# TODO

Improvement proposals for PkCountries library.

## Completed

- [x] Safer `get/1` - returns `nil` instead of crashing, added `get!/1`
- [x] Efficient `exists?/2` - uses `Enum.any?/2` for early termination
- [x] O(1) lookups with compile-time maps (`@countries_by_alpha2`, `@countries_by_alpha3`)
- [x] Added `get_by/2` - get single country by any attribute
- [x] Added `get_by_alpha3/1` - O(1) lookup by alpha3 code
- [x] Simplified `equals_or_contains_in_list/2` with `Enum.any?/2`
- [x] Cleaned up `Application.start(:yamerl)` - now uses `ensure_all_started/1`
- [x] Added `count/0` helper

## Medium Priority

### Cache subdivisions
Subdivisions are read from disk on every `Subdivisions.all/1` call. Options:
- Load at compile time (increases binary size)
- Add ETS-based caching
- Use `persistent_term` for caching

## Low Priority / Nice to Have

### Add `get_subdivision/2`
Get specific subdivision by country and ID:
```elixir
PkCountries.Subdivisions.get("US", "US-CA")
# %PkCountries.Subdivision{id: "US-CA", name: "California", ...}
```

### Add typespec annotations
Add `@spec` for all public functions to enable Dialyzer and improve docs:
```elixir
@spec get(String.t()) :: Country.t() | nil
@spec filter_by(atom(), term()) :: [Country.t()]
```

### Add `eu_members/0` convenience function
```elixir
PkCountries.eu_members()
# [%PkCountries.Country{alpha2: "AT", ...}, ...]
```

### Support filtering by multiple attributes
```elixir
PkCountries.filter_by(region: "Europe", eu_member: true)
```
