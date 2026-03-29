defmodule BeamLabCountries.Subdivisions do
  @moduledoc """
  Module for providing subdivisions related functions.
  """

  alias BeamLabCountries.Subdivision

  @doc """
  Returns all subdivisions by country.

  ## Examples

      iex> country = BeamLabCountries.get("PL")
      iex> BeamLabCountries.Subdivisions.all(country)

  """
  def all(country) do
    country.alpha2
    |> load_subdivisions()
    |> Enum.map(&convert_subdivision/1)
  end

  @doc """
  Returns one subdivision by country and subdivision ID, or `nil` if not found.

  ## Examples

      BeamLabCountries.Subdivisions.get("US", "CA")
      # => %BeamLabCountries.Subdivision{id: "CA", name: "California", ...}

      BeamLabCountries.Subdivisions.get("US", "XX")
      # => nil

  """
  def get(country_code, subdivision_id)
      when is_binary(country_code) and is_binary(subdivision_id) do
    country_code
    |> load_subdivisions()
    |> Enum.find_value(fn {id, data} ->
      if id == subdivision_id, do: convert_subdivision({id, data})
    end)
  end

  def get(%BeamLabCountries.Country{alpha2: alpha2}, subdivision_id) do
    get(alpha2, subdivision_id)
  end

  defp load_subdivisions(country_code) do
    path =
      Path.join([
        :code.priv_dir(:beamlab_countries),
        "data",
        "subdivisions",
        "#{country_code}.yaml"
      ])

    case YamlElixir.read_from_file(path) do
      {:ok, data} -> Map.to_list(data)
      {:error, _} -> []
    end
  end

  defp convert_subdivision({id, data}) do
    %Subdivision{
      id: id,
      name: data["name"],
      unofficial_names: data["unofficial_names"],
      translations: atomize_keys(data["translations"]),
      geo: atomize_keys(data["geo"])
    }
  end

  defp atomize_keys(nil), do: nil

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), atomize_keys(v)} end)
  end

  defp atomize_keys(value), do: value
end
