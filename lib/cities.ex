defmodule BeamLabCountries.Cities do
  @moduledoc """
  Major cities of every country, with populations, coordinates, time zones and
  translated names.

  For each country the data holds its ten largest populated places (by population of the
  city proper, not the metro area) plus the capital. Places that are suburbs of a larger
  place in the same country (closer than 12 km) are left out. For the United States and
  Canada the five largest places of every state and province are included as well, and
  each city carries its `subdivision` ID, see `BeamLabCountries.Subdivisions`.

  Quality is best for large countries; for very small territories GeoNames only knows
  villages and parishes, which is what you get.

  ## Names

  `name` is English, `native_name` is the name in the country's official language, and
  `translations` holds the other locales supported by `BeamLabCountries.Translations`:

      iex> vienna = BeamLabCountries.Cities.capital("AT")
      iex> {vienna.name, vienna.native_name}
      {"Vienna", "Wien"}
      iex> BeamLabCountries.Cities.get_name(vienna, "fr")
      "Vienne"

  Data is loaded at compile time. It comes from [GeoNames](https://www.geonames.org),
  licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
  """

  alias BeamLabCountries.City
  alias BeamLabCountries.Country

  @cities_by_country BeamLabCountries.CityLoader.load()
  @all @cities_by_country
       |> Map.values()
       |> List.flatten()
       |> Enum.sort_by(&{-&1.population, &1.name})
  @by_id Map.new(@all, &{&1.id, &1})
  @by_subdivision Enum.group_by(
                    @all,
                    &{&1.country, &1.subdivision && String.upcase(&1.subdivision)}
                  )
  @capitals for city <- @all, city.capital, into: %{}, do: {city.country, city}
  @default_country_limit 10

  @doc """
  Returns all cities, largest first.

  ## Examples

      iex> BeamLabCountries.Cities.all() |> hd() |> Map.get(:name)
      "Shanghai"

  """
  @spec all() :: [City.t()]
  def all, do: @all

  @doc """
  Returns the total number of cities.

  ## Examples

      iex> BeamLabCountries.Cities.count() > 2000
      true

  """
  @spec count() :: non_neg_integer()
  def count, do: length(@all)

  @doc """
  Returns a city by its GeoNames ID, or `nil` if not found.

  ## Examples

      iex> BeamLabCountries.Cities.get(2761369).name
      "Vienna"

      iex> BeamLabCountries.Cities.get(1)
      nil

  """
  @spec get(integer()) :: City.t() | nil
  def get(id) when is_integer(id), do: Map.get(@by_id, id)
  def get(_id), do: nil

  @doc """
  Returns the largest cities of a country, largest first.

  Accepts a `BeamLabCountries.Country` struct or an alpha2 code (case-insensitive). Returns
  an empty list for unknown countries and countries without data.

  ## Options

    * `:limit` - maximum number of cities, or `:all` for everything in the data
      (default: `#{@default_country_limit}`). The default matters for the United States
      and Canada, which also contain the largest cities of each state or province.

  ## Examples

      iex> BeamLabCountries.Cities.for_country("EE") |> Enum.take(3) |> Enum.map(& &1.name)
      ["Tallinn", "Tartu", "Narva"]

      iex> BeamLabCountries.Cities.for_country("us", limit: 3) |> Enum.map(& &1.name)
      ["New York", "Los Angeles", "Chicago"]

      iex> BeamLabCountries.Cities.for_country("XX")
      []

  """
  @spec for_country(Country.t() | String.t(), keyword()) :: [City.t()]
  def for_country(country, opts \\ [])

  def for_country(%Country{alpha2: alpha2}, opts), do: for_country(alpha2, opts)

  def for_country(country_code, opts) when is_binary(country_code) do
    @cities_by_country
    |> Map.get(String.upcase(country_code), [])
    |> limit(Keyword.get(opts, :limit, @default_country_limit))
  end

  def for_country(_country_code, _opts), do: []

  @doc """
  Returns the largest cities of a subdivision, largest first.

  Only the United States and Canada have subdivision data. Accepts a
  `BeamLabCountries.Country` struct or an alpha2 code; both the country code and the
  subdivision ID are case-insensitive. Takes the same `:limit` option as `for_country/2`
  (default: `:all`).

  ## Examples

      iex> BeamLabCountries.Cities.for_subdivision("US", "CA") |> hd() |> Map.get(:name)
      "Los Angeles"

      iex> BeamLabCountries.Cities.for_subdivision("ca", "on", limit: 1) |> Enum.map(& &1.name)
      ["Toronto"]

      iex> BeamLabCountries.Cities.for_subdivision("DE", "BY")
      []

  """
  @spec for_subdivision(Country.t() | String.t(), String.t(), keyword()) :: [City.t()]
  def for_subdivision(country, subdivision_id, opts \\ [])

  def for_subdivision(%Country{alpha2: alpha2}, subdivision_id, opts),
    do: for_subdivision(alpha2, subdivision_id, opts)

  def for_subdivision(country_code, subdivision_id, opts)
      when is_binary(country_code) and is_binary(subdivision_id) do
    @by_subdivision
    |> Map.get({String.upcase(country_code), String.upcase(subdivision_id)}, [])
    |> limit(Keyword.get(opts, :limit, :all))
  end

  def for_subdivision(_country_code, _subdivision_id, _opts), do: []

  @doc """
  Returns the capital of a country, or `nil` if unknown.

  Accepts a `BeamLabCountries.Country` struct or an alpha2 code.

  ## Examples

      iex> BeamLabCountries.Cities.capital("EE").name
      "Tallinn"

      iex> BeamLabCountries.Cities.capital("XX")
      nil

  """
  @spec capital(Country.t() | String.t()) :: City.t() | nil
  def capital(%Country{alpha2: alpha2}), do: capital(alpha2)

  def capital(country_code) when is_binary(country_code),
    do: Map.get(@capitals, String.upcase(country_code))

  def capital(_country_code), do: nil

  @doc """
  Returns the name of a city in the given locale.

  Locales are those of `BeamLabCountries.Translations.supported_locales/0`; they are
  case-insensitive and regional codes are reduced to their language (`"de-AT"` becomes
  `"de"`). Falls back to the English `name` when there is no translation, which also
  means the locale's name is the same as the English one.

  ## Examples

      iex> munich = BeamLabCountries.Cities.get(2867714)
      iex> BeamLabCountries.Cities.get_name(munich, "de")
      "München"
      iex> BeamLabCountries.Cities.get_name(munich, "ru")
      "Мюнхен"
      iex> BeamLabCountries.Cities.get_name(munich, "xx")
      "Munich"

  """
  @spec get_name(City.t(), String.t()) :: String.t()
  def get_name(%City{translations: translations, name: name}, locale) when is_binary(locale) do
    locale = locale |> String.downcase() |> String.replace("_", "-")
    [language | _] = String.split(locale, "-")

    Map.get(translations, locale) || Map.get(translations, language) || name
  end

  def get_name(%City{name: name}, _locale), do: name

  defp limit(cities, :all), do: cities
  defp limit(cities, n) when is_integer(n) and n >= 0, do: Enum.take(cities, n)
end
