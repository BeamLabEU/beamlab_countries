defmodule BeamLabCountries.City do
  @moduledoc """
  City struct.

  ## Fields

  - `id` - GeoNames ID (integer), stable across releases
  - `name` - preferred English name (e.g. `"Vienna"`), otherwise GeoNames' primary name
  - `native_name` - name in the country's official language (e.g. `"Wien"`); equals `name`
    when no native name is known
  - `translations` - names in other languages, keyed by locale string (e.g. `%{"fr" => "Vienne"}`).
    Only locales whose name differs from `name` are present; use `BeamLabCountries.Cities.get_name/2`
    to look a name up with fallback
  - `country` - alpha2 code of the country
  - `subdivision` - subdivision ID (see `BeamLabCountries.Subdivisions`), only set for the
    United States and Canada
  - `population` - population as recorded by GeoNames; geographic boundaries and dates vary
  - `latitude`, `longitude` - coordinates
  - `timezone` - IANA time zone identifier
  - `capital` - `true` for the capital of the country

  City data comes from [GeoNames](https://www.geonames.org), licensed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
  """

  defstruct [
    :id,
    :name,
    :native_name,
    :country,
    :subdivision,
    :population,
    :latitude,
    :longitude,
    :timezone,
    translations: %{},
    capital: false
  ]

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          native_name: String.t(),
          translations: %{optional(String.t()) => String.t()},
          country: String.t(),
          subdivision: String.t() | nil,
          population: non_neg_integer(),
          latitude: float(),
          longitude: float(),
          timezone: String.t() | nil,
          capital: boolean()
        }
end
