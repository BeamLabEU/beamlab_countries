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
```

## Architecture

BeamLabCountries is a compile-time data library providing ISO 3166 country information, international unions/organizations, language data, and country name translations. All data is loaded from YAML/JSON files at compile time and embedded into modules as module attributes.

### Key Design Pattern

**Compile-time data loading**: Modules use loaders to parse all data during compilation. This means:
- Changes to YAML/JSON files require recompilation (`mix compile --force`)
- No runtime file I/O for lookups (except subdivisions)
- Uses `yaml_elixir` for YAML and `Jason` for JSON parsing
- Pre-built maps for fast lookups (alpha2, alpha3, union membership)

### Module Structure

**Country Modules:**
- `BeamLabCountries` (lib/countries.ex) - Main API: `all/0`, `count/0`, `get/1`, `get!/1`, `get_by/2`, `get_by_alpha3/1`, `filter_by/2`, `exists?/2`
- `BeamLabCountries.Country` (lib/country.ex) - Struct with 39 fields (alpha2, alpha3, name, region, currency, eu_member, eea_member, languages_official, etc.)
- `BeamLabCountries.Loader` (lib/loader.ex) - Compile-time YAML parser for country data

**Subdivisions Modules:**
- `BeamLabCountries.Subdivisions` (lib/subdivisions.ex) - Runtime loader: `all/1`
- `BeamLabCountries.Subdivision` (lib/subdivision.ex) - Struct with 5 fields (id, name, unofficial_names, translations, geo)

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
- `BeamLabCountries.Locale` (lib/locale.ex) - Struct with 7 fields (code, base_code, region_code, name, native_name, flag, country_name)

**Translations Module:**
- `BeamLabCountries.Translations` (lib/translations.ex) - Country name translations: `get_name/2`, `get_all_names/1`, `supported_locales/0`, `locale_supported?/1`

### Data Location

- `priv/data/countries.yaml` - List of country codes to load
- `priv/data/countries/{CODE}.yaml` - Individual country data files (250 countries)
- `priv/data/subdivisions/{CODE}.yaml` - Subdivision data (loaded at runtime, not compile-time)
- `priv/data/unions/{CODE}.yaml` - Union/organization data files (13 unions: eu, nato, g7, g20, etc.)
- `priv/data/languages.json` - Language codes and names (184 languages)
- `priv/data/locales.json` - Regional locale data (85 locales: en-US, es-ES, pt-BR, etc.)
- `priv/data/locales/{LOCALE}.json` - Country name translations (15 locales: ar, de, en, es, fr, it, ja, ko, nl, pl, pt, ru, sv, uk, zh)
