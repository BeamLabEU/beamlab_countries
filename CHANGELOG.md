# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-12-12

### Added

- **Unions module** - Query international organizations (EU, NATO, G7, G20, ASEAN, OPEC, OECD, APEC, Mercosur, USMCA, African Union, EEA, EFTA)
  - `BeamLabCountries.Unions` with functions: `all/0`, `get/1`, `get!/1`, `for_country/1`, `codes_for_country/1`, `member?/2`, `member_countries/1`, `filter_by/2`, `exists?/1`
  - `BeamLabCountries.Union` struct with 8 fields (code, name, type, founded, headquarters, website, wikipedia, members)
- **Locales support** - Regional language variants (e.g., "en-US", "es-MX", "pt-BR")
  - `BeamLabCountries.Locale` struct with 7 fields (code, base_code, region_code, name, native_name, flag, country_name)
  - New `Languages` functions: `get_locale/1`, `all_locales/0`, `all_locale_codes/0`, `locale_count/0`, `locales_for_language/1`, `valid_locale?/1`, `parse_locale/1`
  - 85 locales included
- **Country-language associations** - Find countries by spoken language
  - New `Languages` functions: `countries_for_language/1`, `country_names_for_language/1`, `flags_for_language/1`
- **Language struct** - `BeamLabCountries.Language` struct with 4 fields (code, name, native_name, family)
- **New Languages functions** - `all/0` returns all languages as `Language` structs
- `eea_member` field added to `Country` struct for EEA membership status
- Documentation section in README with correct HexDocs links

### Fixed

- Wikipedia URL in package metadata

## [1.0.0] - 2025-12-10

### Added

- Initial release as `beamlab_countries` (renamed from `pk_countries`)
- **Country data** - 250 countries with 39 fields per country
  - `BeamLabCountries` module with functions: `all/0`, `count/0`, `get/1`, `get!/1`, `get_by/2`, `get_by_alpha3/1`, `filter_by/2`, `exists?/2`
  - `BeamLabCountries.Country` struct with fields including alpha2, alpha3, name, region, currency, eu_member, languages_official, languages_spoken, and more
- **Subdivisions** - States/provinces for countries
  - `BeamLabCountries.Subdivisions` module with `all/1`
  - `BeamLabCountries.Subdivision` struct with 5 fields (id, name, unofficial_names, translations, geo)
- **Languages** - ISO 639-1 language lookup (184 languages)
  - `BeamLabCountries.Languages` module with functions: `get_name/1`, `get_native_name/1`, `get/1`, `all_codes/0`, `count/0`, `valid?/1`
- **Translations** - Country names in 15 languages (ar, de, en, es, fr, it, ja, ko, nl, pl, pt, ru, sv, uk, zh)
  - `BeamLabCountries.Translations` module with functions: `get_name/2`, `get_all_names/1`, `supported_locales/0`, `locale_supported?/1`
- Compile-time data loading for fast runtime lookups
- O(1) lookups for alpha2 and alpha3 codes via pre-built maps
- Requires Elixir 1.18+

### Changed

- Migrated from `yamerl` to `yaml_elixir` for YAML parsing
- `get/1` now returns `nil` instead of raising (use `get!/1` for raising behavior)

[1.0.1]: https://github.com/BeamLabEU/beamlab_countries/compare/1.0.0...HEAD
[1.0.0]: https://github.com/BeamLabEU/beamlab_countries/releases/tag/1.0.0
