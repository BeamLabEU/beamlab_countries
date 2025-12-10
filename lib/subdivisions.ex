defmodule PkCountries.Subdivisions do
  @moduledoc """
  Module for providing subdivisions related functions.
  """

  import PkCountries.Utils, only: [to_map: 1]
  alias PkCountries.Subdivision

  @doc """
  Returns all subdivisions by country.

  ## Examples

      iex> country = PkCountries.get("PL")
      iex> PkCountries.Subdivisions.all(country)

  """
  def all(country) do
    country.alpha2
    |> subdivisions()
    |> Enum.map(&convert_subdivision/1)
  end

  defp convert_subdivision({id, attrs}) do
    Enum.reduce(attrs, %Subdivision{id: id}, fn {attribute, value}, subdivision ->
      attr_atom = List.to_atom(attribute)
      Map.put(subdivision, attr_atom, convert_value(attr_atom, value))
    end)
  end

  defp convert_value(_, :null),
    do: nil

  defp convert_value(:unofficial_names, names),
    do: Enum.map(names, &to_string/1)

  defp convert_value(:translations, names),
    do: to_map(names)

  defp convert_value(:geo, values),
    do: to_map(values)

  defp convert_value(_, value) when is_list(value),
    do: to_string(value)

  defp convert_value(_, value),
    do: value

  defp subdivisions(country_code) do
    Application.ensure_all_started(:yamerl)

    path = Path.join([:code.priv_dir(:pk_countries), "data", "subdivisions", "#{country_code}.yaml"])

    try do
      path
      |> :yamerl.decode_file()
      |> List.first()
    catch
      _exception -> []
    end
  end
end
