defmodule BeamLabCountries.SubdivisionLoader do
  @moduledoc false

  alias BeamLabCountries.Subdivision

  @subdivisions_dir Path.join([:code.priv_dir(:beamlab_countries), "data", "subdivisions"])

  for file <- Path.wildcard(Path.join(@subdivisions_dir, "*.yaml")) do
    @external_resource file
  end

  @doc """
  Loads all subdivision data from YAML files at compile time.

  Returns a map of country alpha2 code => %{upcased subdivision id => Subdivision}.
  """
  def load do
    @subdivisions_dir
    |> Path.join("*.yaml")
    |> Path.wildcard()
    |> Map.new(fn path ->
      code = Path.basename(path, ".yaml")

      subdivisions =
        path
        |> YamlElixir.read_from_file!()
        |> Map.new(fn {id, data} -> {String.upcase(id), convert_subdivision(id, data)} end)

      {code, subdivisions}
    end)
  end

  defp convert_subdivision(id, data) do
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
