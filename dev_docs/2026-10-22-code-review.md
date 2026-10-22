# Pre-release code review — 2026-10-22

Scope: the pending 2.1.0 formats changes (`c9e59bc`), the 2.0.1 city addition
(`9879c62`), the surrounding number/currency and city APIs, generators, CI,
documentation, and Hex package contents. The working tree was clean initially.

## Findings and fixes

1. **BUG — MEDIUM: inconsistent decimal precision validation.**
   `Formats.format_number("US", 1, decimals: 16)` succeeded, while the same call
   with `1.0` crashed inside `Float.round/2`. Validate `0..15` for both input
   types and document the range. Tests cover both boundaries and invalid values.
   This matches [Elixir's supported float precision](https://elixir.hexdocs.pm/1.18/Float.html#round/2).

2. **BUG — MEDIUM: large finite floats crashed during display.**
   `Formats.format_number("US", 1.0e308)` exceeded the VM's fixed float output
   limit. The same helper affected both currency formatters. After rounding,
   whole floats now use integer rendering, which supports their complete digits.
   Regressions use `Float.max_finite()`, including negative amounts and both
   currency APIs. Integer inputs still retain their original precision.

3. **BUG — LOW: BCE dates misplaced the sign.**
   Year `-1` was padded to `00-1`. The year magnitude is now padded before
   adding the sign, producing `-0001`. Tests also cover year zero and short
   positive years.

4. **BUG — MEDIUM: regeneration failed with a missing cache and could leave
   mixed output after a source error.** The generator now creates nested cache
   directories and resolves all source data before rewriting country files.
   An offline regression fails on the second country and verifies that neither
   country changed. This prevents partial updates from source failures; it does
   not promise atomic writes against filesystem errors.

5. **BUG — LOW: CLDR escaped apostrophes were lost.**
   The date converter treated doubled apostrophes as empty literals. It now
   preserves escaped apostrophes inside and outside quoted text and rejects
   unterminated literals. Current country output is unchanged.

6. **PACKAGING — MEDIUM: missing Unicode data notice.**
   The new CLDR-derived format data shipped under an MIT-only package notice.
   `LICENSE.md` now includes the upstream
   [Unicode License V3 notice](https://raw.githubusercontent.com/unicode-org/cldr-json/49.0.0/LICENSE),
   identifies the affected data, and records GeoNames attribution and data
   transformations. Package metadata lists MIT, Unicode-3.0 and CC-BY-4.0.

7. **TEST COVERAGE — LOW: missing-currency test was vacuous.**
   Every stored country has a currency, so filtering for countries without one
   tested nothing. The test now supplies a country struct with no currency and
   checks both `nil` and an explicit currency override. Added direct unknown
   country/date cases, negative localized currency cases, and generator tests
   in CI. Generator documentation now spells out regional-before-bare locale
   selection accurately.

No additional defect was found in the reviewed city lookup and selection code.
Existing city API/data checks and all nine offline city-generator tests pass.

## Validation

- `mix test`: **161 doctests, 237 tests, zero failures** on Elixir 1.19.6 / OTP 28.
- Clean isolated `mix test`: **161 doctests, 237 tests, zero failures** on
  Elixir 1.18.4 / OTP 28, covering the declared minimum Elixir series.
- Format-generator tests: **11 passed**; city-generator tests: **9 passed**.
- Regenerated all **250** country files in a temporary copy using the cached
  CLDR 49 source files: **byte-for-byte identical output**.
- `mix precommit`: passed forced compilation with warnings as errors, unused
  dependency check, Hex advisory audit, format check, strict Credo and Dialyzer
  (**zero errors**).
- `mix docs --warnings-as-errors`: passed.
- `mix hex.build`: built `beamlab_countries-2.1.0.tar`. Inspected the nested
  archive: 250 country YAML files, 244 city JSON files, current formatter source
  and complete license notice included; no PLTs or Python caches.
- `git diff --check`: passed.

The version remains **2.1.0**. The changelog describes the final pre-release
behavior. Fixes remain local for review; no push, tag or Hex publication was
performed.
