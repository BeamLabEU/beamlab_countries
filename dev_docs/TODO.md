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

## Medium Priority

### Cache subdivisions
Subdivisions are read from disk on every `Subdivisions.all/1` call. Options:
- Load at compile time (increases binary size)
- Add ETS-based caching
- Use `persistent_term` for caching

## Low Priority / Nice to Have

### Add typespec annotations
Add `@spec` for all public functions to enable Dialyzer and improve docs:
```elixir
@spec get(String.t()) :: Country.t() | nil
@spec filter_by(atom(), term()) :: [Country.t()]
```
