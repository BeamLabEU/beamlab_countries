defmodule BeamLabCountries.CityLoader do
  @moduledoc false

  alias BeamLabCountries.City

  @cities_dir Path.join([:code.priv_dir(:beamlab_countries), "data", "cities"])
  @pattern Path.join(@cities_dir, "*.json")

  for file <- Path.wildcard(@pattern) do
    @external_resource file
  end

  # `@external_resource` only tracks files that already exist, so also
  # recompile when a data file is added or removed.
  @files_hash :erlang.md5(Path.wildcard(@pattern))

  @doc false
  def __mix_recompile__?, do: :erlang.md5(Path.wildcard(@pattern)) != @files_hash

  @doc """
  Loads all city data from JSON files at compile time.

  Returns a map of country alpha2 code => cities sorted by population (descending).
  """
  def load do
    @pattern
    |> Path.wildcard()
    |> Map.new(fn path ->
      code = country_code!(path)

      cities =
        path
        |> File.read!()
        |> JSON.decode!()
        |> Enum.map(&convert_city(code, &1))
        |> Enum.sort_by(&{-&1.population, &1.name})

      {code, cities}
    end)
  end

  defp country_code!(path) do
    code = Path.basename(path, ".json")

    if code =~ ~r/\A[A-Z]{2}\z/ do
      code
    else
      raise ArgumentError,
            "city data file #{path} must be named after an uppercase alpha2 country code"
    end
  end

  defp convert_city(country, data) do
    %City{
      id: data["id"],
      name: data["name"],
      native_name: data["native_name"],
      translations: data["translations"] || %{},
      country: country,
      subdivision: data["subdivision"],
      population: data["population"],
      latitude: data["latitude"],
      longitude: data["longitude"],
      timezone: data["timezone"],
      capital: data["capital"] == true
    }
  end
end
