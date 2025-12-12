# BeamLabCountries

BeamLabCountries is a collection of all sorts of useful information for every country in the [ISO 3166](https://en.wikipedia.org/wiki/ISO_3166) standard. It includes country data, subdivisions (states/provinces), international organizations, language information, and country name translations.

It is based on the data from the pretty popular but abandoned Elixir library [Countries](https://hex.pm/packages/countries) and previously the Ruby Gem [Countries](https://github.com/hexorx/countries).

## Installation

```elixir
defp deps do
  [
    {:beamlab_countries, "~> 1.0"}
  ]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile beamlab_countries.

## Documentation

Full documentation is available at [HexDocs](https://hexdocs.pm/beamlab_countries).

- [BeamLabCountries](https://hexdocs.pm/beamlab_countries/BeamLabCountries.html) - Main country API
- [BeamLabCountries.Unions](https://hexdocs.pm/beamlab_countries/BeamLabCountries.Unions.html) - International organizations
- [BeamLabCountries.Languages](https://hexdocs.pm/beamlab_countries/BeamLabCountries.Languages.html) - Languages and locales
- [BeamLabCountries.Translations](https://hexdocs.pm/beamlab_countries/BeamLabCountries.Translations.html) - Country name translations
- [BeamLabCountries.Subdivisions](https://hexdocs.pm/beamlab_countries/BeamLabCountries.Subdivisions.html) - States/provinces

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
# 92
```

Check if a country exists:

```elixir
BeamLabCountries.exists?(:name, "Poland")
# true

BeamLabCountries.exists?(:alpha2, "XX")
# false
```

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

### International Organizations (Unions)

Query international organizations and their member countries:

```elixir
alias BeamLabCountries.Unions

# Get all unions
Unions.all()
# Returns 13 unions: EU, NATO, G7, G20, ASEAN, OPEC, OECD, APEC, Mercosur, USMCA, African Union, EEA, EFTA

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
# "中文"

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
# Returns 85 locales sorted by name

Languages.locale_count()
# 85

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
# 92

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

# Get country name in all supported languages
Translations.get_all_names("IT")
# %{"ar" => "إيطاليا", "de" => "Italien", "en" => "Italy", "es" => "Italia",
#   "fr" => "Italie", "ja" => "イタリア", "ko" => "이탈리아", ...}

# Check supported locales
Translations.supported_locales()
# ["ar", "de", "en", "es", "fr", "it", "ja", "ko", "nl", "pl", "pt", "ru", "sv", "uk", "zh"]

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

This software is licensed under [the MIT license](./LICENSE.md).
