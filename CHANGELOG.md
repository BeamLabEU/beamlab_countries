# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2025-12-17
- Update VAT rates for Estonia, Finland, Slovakia (2025)
- Fix language_locales not being loaded from YAML files 

## [1.0.4] - 2025-12-17
- Add language_locales field for dialect/locale specification

Added new language_locales field to Country struct and YAML files that maps base language codes to their specific regional variants. This allows applications to know which dialect is used in each country (e.g., Estonia uses en-GB, not en-US).

## [1.0.3] - 2025-12-16
- Added continent, region & subregion 
- Expand languages_spoken to include widely used languages 

Updated ~70 country YAML files to include commonly spoken languages
beyond just official languages. Added languages used in business,
education, tourism, and by significant minority populations.

## Europe

### Baltic States
- Estonia (EE): Russian (ru), English (en)
- Latvia (LV): Russian (ru), English (en)
- Lithuania (LT): Russian (ru), English (en), Polish (pl)

### Eastern Europe
- Ukraine (UA): Russian (ru), English (en)
- Belarus (BY): English (en)
- Moldova (MD): Russian (ru), Ukrainian (uk), English (en)
- Poland (PL): English (en), German (de)
- Czech Republic (CZ): English (en), German (de)
- Slovakia (SK): Czech (cs), Hungarian (hu), English (en)
- Hungary (HU): English (en), German (de)
- Romania (RO): Hungarian (hu), English (en), French (fr)
- Bulgaria (BG): Turkish (tr), English (en), Russian (ru)
- Russia (RU): English (en), Tatar (tt), Ukrainian (uk)

### Nordic Countries
- Sweden (SE): English (en), Finnish (fi)
- Norway (NO): English (en)
- Denmark (DK): English (en), German (de)
- Finland (FI): English (en), Russian (ru)
- Iceland (IS): English (en), Danish (da)
- Faroe Islands (FO): Danish (da), English (en)
- Greenland (GL): Danish (da), English (en)

### Western Europe
- Germany (DE): English (en), Turkish (tr), Russian (ru)
- France (FR): English (en), Arabic (ar), German (de)
- Netherlands (NL): English (en), German (de), French (fr)
- Belgium (BE): English (en)
- Austria (AT): English (en), Turkish (tr), Croatian (hr)
- Switzerland (CH): Romansh (rm), English (en)
- Luxembourg (LU): English (en), Portuguese (pt)
- Liechtenstein (LI): English (en)
- Monaco (MC): Italian (it), English (en)

### Southern Europe
- Spain (ES): Catalan (ca), Galician (gl), Basque (eu), English (en)
- Italy (IT): English (en), German (de), French (fr)
- Portugal (PT): English (en), Spanish (es), French (fr)
- Greece (GR): English (en), French (fr), German (de)
- Croatia (HR): English (en), German (de), Italian (it)
- Slovenia (SI): English (en), German (de), Croatian (hr), Italian (it)
- Malta (MT): Italian (it)
- Andorra (AD): Spanish (es), French (fr), Portuguese (pt)
- San Marino (SM): English (en)
- Gibraltar (GI): Spanish (es)

### Balkans
- Serbia (RS): Hungarian (hu), English (en), Romanian (ro)
- Bosnia and Herzegovina (BA): English (en)
- Montenegro (ME): English (en)
- North Macedonia (MK): Albanian (sq), Turkish (tr), English (en)
- Albania (AL): English (en), Italian (it), Greek (el)

### British Isles & Channel Islands
- United Kingdom (GB): Welsh (cy), Scottish Gaelic (gd), Polish (pl)
- Ireland (IE): Polish (pl)
- Jersey (JE): Portuguese (pt)
- Guernsey (GG): Portuguese (pt)

### Other European
- Turkey (TR): Kurdish (ku), English (en), Arabic (ar)
- Cyprus (CY): English (en)
- Vatican (VA): English (en), German (de), French (fr)

## Asia

### East Asia
- Japan (JP): English (en)
- China (CN): English (en)
- South Korea (KR): English (en)
- Taiwan (TW): English (en)

### Southeast Asia
- Singapore (SG): Chinese (zh)
- Malaysia (MY): Chinese (zh), Tamil (ta)
- Indonesia (ID): Javanese (jv), English (en)
- Philippines (PH): Cebuano (ceb)
- Thailand (TH): English (en), Chinese (zh)
- Vietnam (VN): English (en), Chinese (zh)
- Cambodia (KH): English (en), French (fr)
- Laos (LA): English (en), French (fr)
- Myanmar (MM): English (en)

### South Asia
- India (IN): Bengali (bn), Telugu (te), Tamil (ta), Marathi (mr)
- Pakistan (PK): Punjabi (pa), Sindhi (sd)
- Bangladesh (BD): English (en)
- Nepal (NP): English (en)
- Sri Lanka (LK): English (en)

### Central Asia
- Kazakhstan (KZ): English (en)
- Uzbekistan (UZ): English (en)

### Middle East
- United Arab Emirates (AE): English (en), Hindi (hi), Urdu (ur)
- Saudi Arabia (SA): English (en)
- Israel (IL): English (en), Russian (ru)
- Qatar (QA): English (en)
- Kuwait (KW): English (en)
- Bahrain (BH): English (en)
- Oman (OM): English (en)
- Jordan (JO): English (en)
- Lebanon (LB): English (en)

## Americas

### North America
- United States (US): Spanish (es), Chinese (zh)
- Canada (CA): Chinese (zh), Punjabi (pa)
- Mexico (MX): English (en)

### South America
- Brazil (BR): English (en), Spanish (es)
- Argentina (AR): English (en)
- Colombia (CO): English (en)
- Chile (CL): English (en)
- Peru (PE): Quechua (qu), Aymara (ay), English (en)

## Oceania
- Australia (AU): Chinese (zh), Arabic (ar), Vietnamese (vi)
- New Zealand (NZ): Maori (mi), Chinese (zh)

## Africa
- Egypt (EG): English (en), French (fr)
- Nigeria (NG): Hausa (ha), Yoruba (yo), Igbo (ig)

## [1.0.2] - 2025-12-15
- Fix VAT rates being displayed as charlists instead of integer lists when single-digit reduced rates are parsed from YAML.

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
