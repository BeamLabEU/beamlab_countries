defmodule BeamLabCountries.UnionLoader do
  @moduledoc false

  alias BeamLabCountries.Union

  @data_dir Path.join([:code.priv_dir(:beamlab_countries), "data"])

  @external_resource Path.join(@data_dir, "unions.yaml")
  for file <- Path.wildcard(Path.join([@data_dir, "unions", "*.yaml"])) do
    @external_resource file
  end

  @doc """
  Loads all union data from YAML files at compile time.
  """
  def load do
    data_path("unions.yaml")
    |> YamlElixir.read_from_file!()
    |> Enum.map(fn code ->
      data_path("unions/#{code}.yaml")
      |> YamlElixir.read_from_file!()
      |> Map.fetch!(code)
      |> convert_union()
    end)
  end

  defp data_path(path) do
    Path.join([:code.priv_dir(:beamlab_countries), "data", path])
  end

  defp convert_union(data) do
    %Union{
      code: data["code"],
      name: data["name"],
      type: convert_type(data["type"]),
      founded: data["founded"],
      headquarters: data["headquarters"],
      website: data["website"],
      wikipedia: data["wikipedia"],
      members: data["members"] || []
    }
  end

  defp convert_type(nil), do: nil
  defp convert_type(type) when is_binary(type), do: String.to_atom(type)
end
