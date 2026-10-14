defmodule BeamLabCountries.SubdivisionLoader do
  @moduledoc false

  alias BeamLabCountries.Subdivision

  @subdivisions_dir Path.join([:code.priv_dir(:beamlab_countries), "data", "subdivisions"])

  for file <- Path.wildcard(Path.join(@subdivisions_dir, "*.yaml")) do
    @external_resource file
  end

  # `@external_resource` only tracks files that already exist, so also
  # recompile when a data file is added or removed.
  @files_hash :erlang.md5(Path.wildcard(Path.join(@subdivisions_dir, "*.yaml")))

  @doc false
  def __mix_recompile__? do
    :erlang.md5(Path.wildcard(Path.join(@subdivisions_dir, "*.yaml"))) != @files_hash
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
      code = country_code!(path)

      subdivisions =
        path
        |> YamlElixir.read_from_file!()
        |> Map.new(fn {id, data} -> {String.upcase(id), convert_subdivision(id, data)} end)

      {code, subdivisions}
    end)
  end

  # Lookups upcase the country code, so a file such as `Ky.yaml` would be
  # silently unreachable. Fail the build instead.
  defp country_code!(path) do
    code = Path.basename(path, ".yaml")

    if code =~ ~r/\A[A-Z]{2}\z/ do
      code
    else
      raise ArgumentError,
            "subdivision data file #{path} must be named after an uppercase alpha2 country code"
    end
  end

  defp convert_subdivision(id, data) do
    translations = atomize_keys(data["translations"])

    %Subdivision{
      id: id,
      name: data["name"] || get_in(translations || %{}, [:en]),
      unofficial_names: List.wrap(data["unofficial_names"]),
      translations: translations,
      geo: atomize_keys(data["geo"])
    }
  end

  defp atomize_keys(nil), do: nil

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), atomize_keys(v)} end)
  end

  defp atomize_keys(value), do: value
end
