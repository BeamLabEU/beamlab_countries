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
