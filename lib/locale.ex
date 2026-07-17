defmodule BeamLabCountries.Locale do
  @moduledoc """
  Locale struct representing a language with regional variant (e.g., "en-US", "es-MX").

  Locales combine a base ISO 639-1 language code with an ISO 3166-1 alpha-2 country code
  to represent regional language variants.

  ## Fields

  - `code` - Full locale code (e.g., "en-US", "es-ES", "pt-BR")
  - `base_code` - Base ISO 639-1 language code (e.g., "en", "es", "pt")
  - `region_code` - ISO 3166-1 alpha-2 country code (e.g., "US", "ES", "BR")
  - `name` - English display name (e.g., "English (United States)")
  - `native_name` - Native display name (e.g., "Español (España)")
  - `flag` - Flag emoji for the region (e.g., "🇺🇸"), derived from Country data
  - `country_name` - Full country name (e.g., "United States of America"), derived from Country data
  - `continent` - Continent name (e.g., "North America"), derived from Country data
  - `region` - Geographic region (e.g., "Americas"), derived from Country data
  - `subregion` - Geographic subregion (e.g., "Northern America"), derived from Country data

  ## Examples

      iex> BeamLabCountries.Languages.get_locale("en-US")
      %BeamLabCountries.Locale{
        code: "en-US",
        base_code: "en",
        region_code: "US",
        name: "English (United States)",
        native_name: "English (US)",
        flag: "🇺🇸",
        country_name: "United States of America",
        continent: "North America",
        region: "Americas",
        subregion: "Northern America"
      }

  """

  defstruct [
    :code,
    :base_code,
    :region_code,
    :name,
    :native_name,
    :flag,
    :country_name,
    :continent,
    :region,
    :subregion
  ]

  @type t :: %__MODULE__{
          code: String.t(),
          base_code: String.t(),
          region_code: String.t(),
          name: String.t(),
          native_name: String.t(),
          flag: String.t() | nil,
          country_name: String.t() | nil,
          continent: String.t() | nil,
          region: String.t() | nil,
          subregion: String.t() | nil
        }
end
