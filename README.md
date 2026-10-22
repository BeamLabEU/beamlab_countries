# BEAM Lab Countries

BeamLabCountries is a collection of all sorts of useful information for every country in the [ISO 3166](https://en.wikipedia.org/wiki/ISO_3166) standard. It includes country data, subdivisions (states/provinces), international organizations, language information, and country name translations.

It is based on the data from the pretty popular but abandoned Elixir library [Countries](https://hex.pm/packages/countries) and previously the Ruby Gem [Countries](https://github.com/hexorx/countries).

## Installation

```elixir
defp deps do
  [
    {:beamlab_countries, "~> 2.0"}
  ]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile beamlab_countries.

## Documentation

Full documentation is available at [HexDocs](https://beamlab-countries.hexdocs.pm).

- [BeamLabCountries](https://beamlab-countries.hexdocs.pm/BeamLabCountries.html) - Main country API
- [BeamLabCountries.Formats](https://beamlab-countries.hexdocs.pm/BeamLabCountries.Formats.html) - Number, date and currency formatting
- [BeamLabCountries.Unions](https://beamlab-countries.hexdocs.pm/BeamLabCountries.Unions.html) - International organizations
- [BeamLabCountries.Languages](https://beamlab-countries.hexdocs.pm/BeamLabCountries.Languages.html) - Languages and locales
- [BeamLabCountries.Translations](https://beamlab-countries.hexdocs.pm/BeamLabCountries.Translations.html) - Country name translations
- [BeamLabCountries.Subdivisions](https://beamlab-countries.hexdocs.pm/BeamLabCountries.Subdivisions.html) - States/provinces
- [BeamLabCountries.Cities](https://beamlab-countries.hexdocs.pm/BeamLabCountries.Cities.html) - Major cities

## Usage

### Countries

Get all countries:

```elixir
countries = BeamLabCountries.all()
Enum.count(countries)
# 250
```

Get a single country by alpha2 or alpha3 code:

```elixir
country = BeamLabCountries.get("PL")
# %BeamLabCountries.Country{name: "Poland", alpha2: "PL", alpha3: "POL", ...}

country = BeamLabCountries.get_by_alpha3("DEU")
# %BeamLabCountries.Country{name: "Germany", alpha2: "DE", alpha3: "DEU", ...}
```

Filter countries by attribute:

```elixir
# By region
countries = BeamLabCountries.filter_by(:region, "Europe")
Enum.count(countries)
# 51

# By currency
eurozone = BeamLabCountries.filter_by(:currency_code, "EUR")

# By continent
asian_countries = BeamLabCountries.filter_by(:continent, "Asia")

# By EU membership
eu_countries = BeamLabCountries.filter_by(:eu_member, true)

# By language (countries where English is spoken)
english_speaking = BeamLabCountries.filter_by(:languages_spoken, "en")
Enum.count(english_speaking)
# 168
```

Time zones are IANA identifiers, and can be filtered like any other attribute:

```elixir
BeamLabCountries.get("EE").timezones
# ["Europe/Tallinn"]

BeamLabCountries.get("US").timezones |> length()
# 29

BeamLabCountries.get_by(:timezones, "Europe/Tallinn").alpha2
# "EE"
```

`eu_member` and `eea_member` are always booleans, so non-members can be filtered with
`filter_by(:eu_member, false)`. Lookups return `nil` for unknown or non-string codes, while
`filter_by/1,2`, `get_by/2` and `exists?/2` raise `ArgumentError` for attributes that are
not fields of `BeamLabCountries.Country`:

```elixir
BeamLabCountries.get(nil)
# nil

BeamLabCountries.filter_by(:regoin, "Europe")
# ** (ArgumentError) unknown country attribute: :regoin, expected one of: ...
```

Check if a country exists:

```elixir
BeamLabCountries.exists?(:name, "Poland")
# true

BeamLabCountries.exists?(:alpha2, "XX")
# false
```

### Number, date and currency formats

Each country has the decimal and thousands separators, short date pattern and currency pattern
it uses, from [Unicode CLDR](https://cldr.unicode.org). They describe the country's main
language (`number_format_locale`), one format per country:

```elixir
de = BeamLabCountries.get("DE")
{de.decimal_separator, de.thousands_separator, de.date_format, de.currency_format}
# {",", ".", "DD.MM.YYYY", "{{amount}}\u00A0{{symbol}}"}

BeamLabCountries.get("CH") |> Map.take([:decimal_separator, :thousands_separator, :date_format])
# %{decimal_separator: ".", thousands_separator: "'", date_format: "DD.MM.YYYY"}

BeamLabCountries.get("US").date_format
# "M/D/YYYY"
```

Some separators are non-breaking spaces, as in CLDR (Estonia uses `"\u00A0"`, France `"\u202F"`),
so a number is never split across lines. `currency_format` uses `{{amount}}` and `{{symbol}}`
placeholders.

`BeamLabCountries.Formats` applies them to a country struct or an alpha2 code:

```elixir
alias BeamLabCountries.Formats

Formats.format_number("DE", 1234567.891)
# "1.234.567,89"

Formats.format_number("EE", 1234.5)
# "1\u00A0234,50"

Formats.format_number("CH", -1234.5, decimals: 1)
# "-1'234.5"

Formats.format_date("US", ~D[2026-03-07])
# "3/7/2026"

Formats.format_date("DE", ~U[2026-03-07 10:00:00Z])
# "07.03.2026"

Formats.format_currency("GB", 1234.56)
# "£1,234.56"

Formats.format_currency("DE", 1234.56)
# "1.234,56\u00A0€"

# The currency defaults to the country's own; the number of decimals comes from the currency
Formats.format_currency("CH", 1234.56, currency: "CHF")
# "CHF\u00A01'234.56"

Formats.format_currency("JP", 1234)
# "¥1,234"

Formats.format_number("XX", 1)
# nil
```

Digits are grouped by thousands everywhere (no Indian lakh grouping) and dates use the Gregorian
calendar. See `BeamLabCountries.Formats` and `BeamLabCountries.Country` for the details.

### Subdivisions

Get subdivisions (states, provinces, regions) for a country:

```elixir
country = BeamLabCountries.get("BR")
subdivisions = BeamLabCountries.Subdivisions.all(country)
Enum.count(subdivisions)
# 27

# Each subdivision includes id, name, translations, and geo data
hd(subdivisions)
# %BeamLabCountries.Subdivision{id: "AC", name: "Acre", ...}
```

### Cities

Up to ten major cities for each of 244 countries and territories, plus the capital when
identified by GeoNames, with coordinates, time zones and names in 23 languages.
`for_country/2` returns those ten largest places and still includes the capital when it
ranks lower. All 50 US states and all 13 Canadian provinces and territories have at least
ten populated places, including smaller towns and villages where needed.

Populations and translations follow GeoNames and can be incomplete or outdated.
`name` uses the preferred English name when available, otherwise the primary GeoNames name.
`get_name/2` falls back to `name`; English locales always return `name`.

```elixir
alias BeamLabCountries.Cities

Cities.capital("AT").name
# "Vienna"

Cities.for_country("DE") |> Enum.map(& &1.name) |> Enum.take(4)
# ["Berlin", "Hamburg", "Munich", "Cologne"]

Cities.for_country("US") |> length()
# 11 (the 10 largest cities, plus Washington D.C.)

Cities.for_country("US", limit: :all) |> length()
# 501 (every state, plus Washington D.C.)

Cities.for_subdivision("US", "CA", limit: 5) |> Enum.map(& &1.name)
# ["Los Angeles", "San Diego", "San Jose", "San Francisco", "Fresno"]

Cities.for_subdivision("CA", "ON", limit: 2) |> Enum.map(& &1.name)
# ["Toronto", "Ottawa"]

Cities.for_subdivision("CA", "PE", limit: 10) |> length()
# 10 (every Canadian province and territory has at least ten entries)

# Names differ by language: English, native and translated
vienna = Cities.capital("AT")
{vienna.name, vienna.native_name}
# {"Vienna", "Wien"}

Cities.get_name(vienna, "fr")
# "Vienne"

Cities.get_name(Cities.capital("CZ"), "de")
# "Prag"

# GeoNames ID lookup
Cities.get(2761369).population
# 1691468
```

City data comes from [GeoNames](https://www.geonames.org), licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

### International Organizations (Unions)

Query international organizations and their member countries:

```elixir
alias BeamLabCountries.Unions

# Get all unions
Unions.all()
# Returns 29 unions: EU, EEA, EFTA, NATO, G7, G20, APEC, ASEAN, Mercosur, USMCA, African Union,
# OPEC, OECD, BRICS, CIS, OIC, Pacific Alliance, Commonwealth, Arab League, GCC, Schengen,
# Eurozone, SCO, CARICOM, ECOWAS, SADC, EAC, Council of Europe and CPTPP

# Get a specific union
eu = Unions.get("eu")
# %BeamLabCountries.Union{code: "eu", name: "European Union", type: :economic_political, ...}

# Check union membership
Unions.member?("DE", "eu")
# true

Unions.member?("US", "nato")
# true

# Get all unions a country belongs to
Unions.for_country("DE")
# [%Union{code: "eu", ...}, %Union{code: "nato", ...}, %Union{code: "g7", ...}, ...]

Unions.codes_for_country("DE")
# ["eu", "eea", "nato", "g7", "g20", "oecd"]

# Get all member countries of a union
eu_countries = Unions.member_countries("eu")
Enum.count(eu_countries)
# 27

# Filter unions by type
military_unions = Unions.filter_by(:type, :military)
# [%Union{code: "nato", name: "North Atlantic Treaty Organization", ...}]
```

### Languages

Look up language information by ISO 639-1 code:

```elixir
alias BeamLabCountries.Languages

# Get language name
Languages.get_name("de")
# "German"

Languages.get_name("ja")
# "Japanese"

# Get native language name
Languages.get_native_name("de")
# "Deutsch"

Languages.get_native_name("zh")
# "中文 (Zhōngwén), 汉语, 漢語"

# Get full language info as struct
Languages.get("fr")
# %BeamLabCountries.Language{code: "fr", name: "French", native_name: "Français", family: "Indo-European"}

# Get all languages
Languages.all()
# [%Language{code: "aa", name: "Afar", ...}, ...]

Languages.count()
# 184

# Check if a language code is valid
Languages.valid?("en")
# true
```

### Locales

Work with regional language variants (e.g., "en-US", "es-MX", "pt-BR"):

```elixir
alias BeamLabCountries.Languages

# Get a locale with full details including flag and country name
locale = Languages.get_locale("en-US")
# %BeamLabCountries.Locale{
#   code: "en-US",
#   base_code: "en",
#   region_code: "US",
#   name: "English (United States)",
#   native_name: "English (US)",
#   flag: "🇺🇸",
#   country_name: "United States of America"
# }

# Get all locales
Languages.all_locales()
# Returns 140 locales sorted by name

Languages.locale_count()
# 140

# Get all regional variants for a language
Languages.locales_for_language("en")
# [%Locale{code: "en-AU", ...}, %Locale{code: "en-CA", ...}, %Locale{code: "en-GB", ...}, %Locale{code: "en-US", ...}]

Languages.locales_for_language("es")
# [%Locale{code: "es-AR", ...}, %Locale{code: "es-ES", ...}, %Locale{code: "es-MX", ...}, ...]

# Parse a locale code
Languages.parse_locale("pt-BR")
# {"pt", "BR"}

# Check if a locale is valid
Languages.valid_locale?("en-US")
# true
```

### Country-Language Associations

Find countries where a language is spoken:

```elixir
alias BeamLabCountries.Languages

# Get all countries where English is spoken
countries = Languages.countries_for_language("en")
length(countries)
# 168

# Get just the country names
Languages.country_names_for_language("es")
# ["Argentina", "Bolivia", "Chile", "Colombia", "Costa Rica", "Cuba", ...]

# Get flags for countries where a language is spoken
Languages.flags_for_language("fr")
# ["🇧🇪", "🇧🇫", "🇧🇮", "🇧🇯", "🇨🇦", "🇨🇩", "🇨🇫", "🇨🇬", "🇨🇭", "🇨🇮", "🇨🇲", "🇫🇷", ...]
```

### Country Name Translations

Get country names in different languages:

```elixir
alias BeamLabCountries.Translations

# Get country name in a specific language
Translations.get_name("DE", "fr")
# "Allemagne"

Translations.get_name("JP", "de")
# "Japan"

Translations.get_name("US", "zh")
# "美国"

Translations.get_name("FR", "ar")
# "فرنسا"

# Regional locales are reduced to their language, and a fallback can be given
Translations.get_name("AT", "de-AT")
# "Österreich"

Translations.get_name("AT", "xx", fallback: "en")
# "Austria"

# Get country name in all supported languages
Translations.get_all_names("IT")
# %{"ar" => "إيطاليا", "de" => "Italien", "en" => "Italy", "es" => "Italia",
#   "fr" => "Italie", "ja" => "イタリア", "ko" => "이탈리아", ...}

# Check supported locales
Translations.supported_locales()
# ["ar", "cs", "de", "en", "es", "et", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt",
#  "ro", "ru", "sv", "th", "tr", "uk", "vi", "zh"]

Translations.locale_supported?("ja")
# true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright and License

Copyright (c) 2025 Dmitri Don / BeamLab

Copyright (c) 2015-2025 Sebastian Szturo

This software is licensed under the [MIT license](./LICENSE.md). CLDR-derived data is
covered by the Unicode License V3 (notice included in the same file), and city data by
[GeoNames CC BY 4.0](https://www.geonames.org/about.html).
