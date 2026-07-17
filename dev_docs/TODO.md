# TODO

Improvement proposals for BeamLabCountries library.

## Completed

- [x] Safer `get/1` - returns `nil` instead of crashing, added `get!/1`
- [x] Efficient `exists?/2` - uses `Enum.any?/2` for early termination
- [x] O(1) lookups with compile-time maps (`@countries_by_alpha2`, `@countries_by_alpha3`)
- [x] Added `get_by/2` - get single country by any attribute
- [x] Added `get_by_alpha3/1` - O(1) lookup by alpha3 code
- [x] Simplified `equals_or_contains_in_list/2` with `Enum.any?/2`
- [x] Cleaned up `Application.start(:yamerl)` - now uses `ensure_all_started/1`
- [x] Added `count/0` helper
- [x] Added `eu_members/0` convenience function
- [x] Added `filter_by/1` for multi-attribute filtering (keyword list)
- [x] Added `Subdivisions.get/2` - get specific subdivision by country and ID
- [x] Added `BeamLabCountries.Random` module - `country/0`, `flag/0`
- [x] Added `dialyxir` with `mix precommit` and `mix quality` aliases
- [x] Fixed `Currencies.format/3` for negative amounts (sign dropped, double dot)
- [x] Subdivisions embedded at compile time - no runtime disk I/O, path-traversal-safe,
      case-insensitive lookups, `all/1` accepts an alpha2 code (supersedes "Cache subdivisions")
- [x] `yaml_elixir` is now compile-time only (`runtime: false`)
- [x] `@external_resource` for all YAML/JSON data files - data edits trigger recompilation
- [x] Case-insensitive locale lookups (`get_locale/1`, `valid_locale?/1`); `parse_locale/1` upcases region
- [x] `@spec` annotations for all public functions
- [x] Doctest coverage for `Translations`, `Subdivisions`, `Language`, `Locale`; stale examples fixed
- [x] GitHub Actions CI (legacy `.travis.yml` removed)

## Data-Level Work

See `dev_docs/2026-03-28_roadmap.md` for remaining data improvements
(translation locales, missing subdivisions for 26 countries, additional unions,
time zones, borders).
