# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
mix deps.get          # Install dependencies
mix compile           # Compile the project
mix test              # Run all tests
mix test test/countries_test.exs:12  # Run specific test by line number
mix credo --strict    # Run static analysis
mix format            # Format code
mix docs              # Generate documentation
mix precommit         # Run compile + format + credo + dialyzer
mix quality           # Run format + credo + dialyzer
```

## Architecture

BeamLabCountries is a compile-time data library providing ISO 3166 country information, international unions/organizations, language data, and country name translations. All data is loaded from YAML/JSON files at compile time and embedded into modules as module attributes.

### Key Design Pattern

**Compile-time data loading**: Modules use loaders to parse all data during compilation. This means:
- Changes to YAML/JSON files require recompilation (`mix compile --force`)
- No runtime file I/O for lookups
- Uses `yaml_elixir` for YAML and the built-in `JSON` module for JSON parsing
- Pre-built maps for fast lookups (alpha2, alpha3, union membership)

### Module Structure

**Country Modules:**
- `BeamLabCountries` (lib/countries.ex) - Main API: `all/0`, `count/0`, `get/1`, `get!/1`, `get_by/2`, `get_by_alpha3/1`, `filter_by/2`, `exists?/2`
- `BeamLabCountries.Country` (lib/country.ex) - Struct with 37 fields (alpha2, alpha3, name, short_name, phone_prefix, region, currency, eu_member, eea_member, languages_official, timezones, etc.)
- `BeamLabCountries.Loader` (lib/loader.ex) - Compile-time YAML parser for country data
- `BeamLabCountries.Random` (lib/random.ex) - `country/0`, `flag/0`

**Subdivisions Modules:**
- `BeamLabCountries.Subdivisions` (lib/subdivisions.ex) - Compile-time data: `all/1` (sorted by id), `get/2`; both accept a `%Country{}` or alpha2 code
- `BeamLabCountries.Subdivision` (lib/subdivision.ex) - Struct with 5 fields (id, name, unofficial_names, translations, geo)
- `BeamLabCountries.SubdivisionLoader` (lib/subdivision_loader.ex) - Compile-time YAML parser for subdivision data

**Currencies Modules:**
- `BeamLabCountries.Currencies` (lib/currencies.ex) - ISO 4217 lookup: `get/1`, `get!/1`, `name/1`, `symbol/1`, `symbol_native/1`, `decimal_digits/1`, `for_country/1`, `countries_for_currency/1`, `all/0`, `all_codes/0`, `count/0`, `valid?/1`, `format/3`
- `BeamLabCountries.Currency` (lib/currency.ex) - Struct with 6 fields (code, name, name_plural, symbol, symbol_native, decimal_digits)

**Cities Modules:**
- `BeamLabCountries.Cities` (lib/cities.ex) - Compile-time data: `all/0`, `count/0`, `get/1` (GeoNames ID), `for_country/2` (default: 10 largest, plus the capital when it ranks lower; `limit: :all` for everything), `for_subdivision/3` (US/CA only), `capital/1`, `get_name/2` (locale with fallback to English)
- `BeamLabCountries.City` (lib/city.ex) - Struct with 11 fields (id, name, native_name, translations, country, subdivision, population, latitude, longitude, timezone, capital)
- `BeamLabCountries.CityLoader` (lib/city_loader.ex) - Compile-time JSON loader for city data
- Data is generated from GeoNames by `dev_docs/cities/build_cities.py` (see `dev_docs/cities/README.md`); city names are strings-keyed by locale

**Unions Modules (International Organizations):**
- `BeamLabCountries.Unions` (lib/unions.ex) - API: `all/0`, `count/0`, `get/1`, `get!/1`, `for_country/1`, `codes_for_country/1`, `filter_by/2`, `exists?/1`, `member?/2`, `member_countries/1`
- `BeamLabCountries.Union` (lib/union.ex) - Struct with 8 fields (code, name, type, founded, headquarters, website, wikipedia, members)
- `BeamLabCountries.UnionLoader` (lib/union_loader.ex) - Compile-time YAML parser for union data

**Languages & Locales Modules:**
- `BeamLabCountries.Languages` (lib/languages.ex) - Language and locale lookup:
  - Base languages: `get/1`, `get_name/1`, `get_native_name/1`, `all/0`, `all_codes/0`, `count/0`, `valid?/1`
  - Locales: `get_locale/1`, `all_locales/0`, `all_locale_codes/0`, `locale_count/0`, `locales_for_language/1`, `valid_locale?/1`, `parse_locale/1`
  - Country associations: `countries_for_language/1`, `country_names_for_language/1`, `flags_for_language/1`
- `BeamLabCountries.Language` (lib/language.ex) - Struct with 4 fields (code, name, native_name, family)
- `BeamLabCountries.Locale` (lib/locale.ex) - Struct with 10 fields (code, base_code, region_code, name, native_name, flag, country_name, continent, region, subregion)

**Translations Module:**
- `BeamLabCountries.Translations` (lib/translations.ex) - Country name translations: `get_name/2,3`, `get_all_names/1`, `supported_locales/0`, `locale_supported?/1`

### Data Location

- `priv/data/countries.yaml` - List of country codes to load
- `priv/data/countries/{CODE}.yaml` - Individual country data files (250 countries)
- `priv/data/subdivisions/{CODE}.yaml` - Subdivision data (224 countries). File names must be uppercase alpha2 codes; the loader fails the build otherwise
- `priv/data/cities/{CODE}.json` - Major cities per country (244 countries, 2,621 places; at least 10 per US state and Canadian province/territory; GeoNames CC BY 4.0, generated, see above)
- `priv/data/unions.yaml` / `priv/data/unions/{CODE}.yaml` - Union/organization data files (29 unions: eu, nato, g7, g20, brics, schengen, eurozone, etc.)
- `priv/data/languages.json` - Language codes and names (184 languages)
- `priv/data/currencies.json` - ISO 4217 currency data (157 currencies)
- `priv/data/locales.json` - Regional locale data (140 locales: en-US, es-ES, pt-BR, etc.)
- `priv/data/locales/{LOCALE}.json` - Country name translations (23 locales: ar, cs, de, en, es, et, fr, hi, id, it, ja, ko, nl, pl, pt, ro, ru, sv, th, tr, uk, vi, zh)
