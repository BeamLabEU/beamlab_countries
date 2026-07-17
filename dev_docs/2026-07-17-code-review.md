# Code Review - 2026-07-17

**Scope:** Full review of beamlab_countries 1.0.8 (all of `lib/`, tests, docs, build config).
**Baseline state:** `mix test` green (96 doctests, 148 tests, 0 failures), `mix credo --strict` clean, `mix dialyzer` clean, `mix format --check-formatted` clean.

All findings below were verified by executing the code, not just reading it.

---

## Bugs

### 1. `Currencies.format/3` broken for negative amounts

`lib/currencies.ex:363` (`format_number/2`)

```elixir
BeamLabCountries.Currencies.format(-1234.56, "USD")  # => "$-1,234..56"  (double dot)
BeamLabCountries.Currencies.format(-0.5, "USD")      # => "$0..50"        (sign lost + double dot)
```

Root cause: for negative amounts, `decimal = rounded - trunc(rounded)` is negative, so
`:erlang.float_to_binary(decimal, decimals: n)` returns e.g. `"-0.56"`. The code then strips
two characters assuming a `"0."` prefix, keeping the `.`, and prepends another `"."`.
For amounts in `-1..0`, `trunc/1` additionally discards the sign entirely.

Fix: extract the sign before rounding and operate on the absolute value:

```elixir
defp format_number(amount, decimal_digits) do
  sign = if amount < 0, do: "-", else: ""
  rounded = Float.round(abs(amount) / 1, decimal_digits)
  # ... rest unchanged, prepend `sign` to the result
end
```

Also add: `@spec format(number(), String.t(), keyword()) :: String.t() | nil` and
negative-amount tests (none exist today).

### 2. Path traversal in `Subdivisions`

`lib/subdivisions.ex:48-61` (`load_subdivisions/1`)

`country_code` is interpolated into a filesystem path without any validation:

```elixir
BeamLabCountries.Subdivisions.get("../unions", "eu")
# ** (BadMapError) expected a map, got: ["eu", "eea", "efta", ...]
```

Consequences:

- `../../...` reads any `.yaml` file readable by the BEAM process.
- A list-shaped YAML crashes the caller with `BadMapError` (`Map.to_list/1` on a list).
- A map-shaped YAML returns its keys as "subdivisions" (information disclosure).
- `convert_subdivision/1` calls `String.to_atom/1` on parsed keys **at runtime**,
  so attacker-controlled YAML doubles as an atom-table-exhaustion vector.

Fix: validate before building the path (and upcase, see #3):

```elixir
@alpha2_format ~r/^[A-Za-z]{2}$/

def get(country_code, subdivision_id)
    when is_binary(country_code) and is_binary(subdivision_id) do
  if country_code =~ @alpha2_format do
    country_code |> String.upcase() |> ... 
  else
    nil
  end
end
```

### 3. Inconsistent case handling across the public API

| Call | Result | Note |
|------|--------|------|
| `BeamLabCountries.get("pl")` | works | upcased internally |
| `Subdivisions.get("us", "CA")` | `nil` | path lookup is case-sensitive |
| `Subdivisions.get("US", "ca")` | `nil` | subdivision ID case-sensitive |
| `Languages.valid?("EN")` | `true` | downcased internally |
| `Languages.valid_locale?("EN-US")` | `false` | `lib/languages.ex:364` — no normalization |
| `Languages.parse_locale("EN-us")` | `{"en", "us"}` | `lib/languages.ex:383` — base downcased, region NOT upcased |

Recommendation: pick one convention and apply it everywhere —
upcase country/region codes, downcase language codes, case-insensitive subdivision IDs.

### 4. Country/union YAML changes do not trigger recompilation

`Currencies`, `Languages`, and `Translations` declare `@external_resource` for their JSON
data files; `BeamLabCountries` (`lib/countries.ex:205`) and `Unions` (`lib/unions.ex:27`)
do not for their YAML files.

Verified:

```bash
touch priv/data/countries/PL.yaml priv/data/unions/eu.yaml && mix compile
# => nothing recompiles (stale embedded data ships)
touch priv/data/currencies.json && mix compile
# => Compiling 15 files (.ex)
```

Fix in `countries.ex` (and analogously in `unions.ex`):

```elixir
@data_dir Path.join([:code.priv_dir(:beamlab_countries), "data"])
@external_resource Path.join(@data_dir, "countries.yaml")
for file <- Path.wildcard(Path.join(@data_dir, "countries/*.yaml")) do
  @external_resource file
end
```

### 5. Dead / broken doctests

- `Random.flag/0` (`lib/random.ex:24-25`) doctest expects `"\xF0\x9F\x87\xBA\x93"` —
  5 bytes, invalid UTF-8. A flag emoji is two 4-byte regional indicators (8 bytes).
  This can never pass; random output cannot be doctested at all. Rewrite as a plain
  example without `iex>`, or assert a property instead (`String.valid?(flag)`).
- `Translations` has **no test file at all** — its ~15 doctest examples never execute.
- `Language`, `Locale`, `Random`, `Subdivisions` contain `iex>` examples in docs that
  no test module opts into via `doctest`.

Fix: add `test/translations_test.exs` with `doctest BeamLabCountries.Translations`,
add `doctest` for `Language`, `Locale`, `Subdivisions` (after making their examples
deterministic), fix the `Random.flag` example. This makes doc drift fail CI.

---

## Documentation drift

| Location | Says | Actual |
|----------|------|--------|
| `lib/currencies.ex:6` moduledoc | 164 currencies | 155 (proven by its own `count()` doctest) |
| `README.md` (Locales section, 2x) | 85 locales | 140 (`Languages.locale_count()`) |
| `dev_docs/2026-03-28_roadmap.md` | "Add ASEAN / African Union / Mercosur" open | all 3 already shipped (`Unions.all()` returns 13 unions incl. `asean`, `african_union`, `mercosur`) |

---

## Improvements

### Subdivision loading (already TODO "Medium Priority")

Every `Subdivisions.all/1` / `get/2` call re-reads and re-parses YAML from disk at
runtime. This also forces `yaml_elixir` (+ `yamerl`) to remain a **runtime** dependency
in every downstream release.

Recommendation: embed subdivisions at compile time like countries (224 files, small)
— removes disk I/O and the runtime YAML dependency in one move. `persistent_term`
caching is the fallback if binary size becomes a concern.

### `@spec` coverage (already TODO "Low Priority")

Only `Unions` and `Random` are fully specced. Missing: `countries.ex`, `currencies.ex`,
`languages.ex`, `translations.ex`, `subdivisions.ex`. Dialyzer is half-blind today —
part of why bugs #1 and #2 went unnoticed.

Also: `Country.t` marks **every** field `| nil`. Making `alpha2`, `alpha3`, `name`
required (`String.t()`, no nil) would give Dialyzer real teeth.

### `Subdivisions.all/1` API symmetry

`all/1` accepts only a `%Country{}` struct; `get/2` accepts both struct and alpha2 code.
Accept `String.t()` in `all/1` too.

### `Currencies.format/3` float math

Fine for display, but: floats lose precision for very large amounts and money generally
wants decimal arithmetic. Document that `format/3` is display-only, and consider a
`format_cents/2` accepting integer minor units to sidestep float issues.

### CI

`.travis.yml` is legacy. Replace with a small GitHub Actions workflow running
`mix precommit` (compile `--warnings-as-errors`, `deps.unlock --check-unused`,
`hex.audit`, format check, credo, dialyzer) on PRs.

### Trivia

- `lib/languages.ex:44`: no-op `Map.new(fn {code, data} -> {code, data} end)` — remove.
- `atomize_keys/1` duplicated in `lib/loader.ex:70` and `lib/subdivisions.ex:75` —
  acceptable, or extract to a shared helper.

---

## Recommended order of work

1. **Fix `format/3` negatives + tests** (#1) — user-visible wrong output.
2. **Validate country codes in `Subdivisions`** (#2, #3) — security/crash vector.
3. **Add `@external_resource`** (#4) — silent stale-data risk on every data edit.
4. **Doctest coverage + fix `Random.flag` example** (#5) + doc-count fixes — cheap, prevents recurrence.
5. Roadmap items: `@spec` coverage, subdivision compile-time embedding, CI migration.


---

# Work Log - 2026-07-17

All bugs and improvements from the review above have been implemented and verified.
This section records what was done, what was found along the way, and the final state.

## Resolution per finding

### Bug 1 - `Currencies.format/3` negatives: FIXED

`lib/currencies.ex` `format_number/2` now extracts the sign and rounds `abs(amount)`.
Added doctests (`format(-1234.56, "USD") == "$-1,234.56"`, `format(-0.5, "USD") == "$-0.50"`),
a `@spec`, and a doc note that the function is display-only (float arithmetic).

### Bug 2 - Path traversal in `Subdivisions`: FIXED (by design)

Subdivision data is now **embedded at compile time** (new `lib/subdivision_loader.ex`,
mirroring `Loader`/`UnionLoader`). `lib/subdivisions.ex` no longer touches the filesystem
at runtime at all, so the traversal vector and the `BadMapError` crash are gone, and no
runtime `String.to_atom/1` happens on YAML keys either (atomization moved to compile time).

### Bug 3 - Case handling: FIXED

Convention chosen: upcase country/region codes, downcase language codes,
case-insensitive subdivision IDs.

- `Subdivisions.all/1` / `get/2` upcase the country code; subdivision map keys are stored
  upcased at load time, so `get("us", "ca") == get("US", "CA")`.
- `Languages.get_locale/1` and `valid_locale?/1` normalize via new private
  `normalize_locale_code/1` (`"EN-us"` -> `"en-US"`).
- `Languages.parse_locale/1` now upcases the region: `"EN-us"` -> `{"en", "US"}`.

### Bug 4 - `@external_resource`: FIXED

`lib/loader.ex`, `lib/union_loader.ex`, `lib/subdivision_loader.ex` register every data
file (`countries.yaml` + `countries/*.yaml`, `unions.yaml` + `unions/*.yaml`,
`subdivisions/*.yaml`). Verified: content edits recompile the loader plus its
compile-time dependents.

**Discovery:** Mix 1.19 tracks `@external_resource` staleness by **content digest**, not
mtime — a plain `touch` no longer triggers recompilation. Testing this properly requires
editing file content.

### Bug 5 - Dead/broken doctests: FIXED

- `Random.flag/0` example rewritten as a non-`iex>` property example (`String.valid?/1`).
- New `test/translations_test.exs` (module had zero tests) with `doctest` + unit tests.
- `doctest` enabled for `Subdivisions`, `Language`, `Locale`.
- **Two stale examples exposed and fixed** (they were never executed before):
  - `Translations` moduledoc: `get_name("US", "ja")` is `"米国"` in the data, not
    `"アメリカ合衆国"`.
  - `Locale` moduledoc: struct example was missing the populated
    `continent`/`region`/`subregion` fields.

### Documentation drift: FIXED

- `currencies.ex` moduledoc: 164 -> 155 currencies.
- README: 85 -> 140 locales (2x); 92 -> 167 English-speaking countries (2x, both
  `filter_by/2` and `Languages.countries_for_language/1` examples).
- Roadmap: ASEAN, African Union, Mercosur checked off (already shipped).

### Improvements: DONE

- **Subdivision compile-time embedding** - see Bug 2. Side effect: `yaml_elixir` is now
  `runtime: false` in `mix.exs` (compile-time only; no YAML parser in downstream releases).
  Required `plt_add_apps: [:ex_unit, :yaml_elixir, :yamerl]` in `mix.exs` so dialyzer's PLT
  still includes the compile-time dep — verified with a from-scratch PLT build.
  Cost note: `subdivisions.ex` takes >10s to compile (2.6MB of YAML); full clean compile
  of the project is still well under a minute.
- **`@spec` coverage** - all public functions in `countries.ex`, `currencies.ex`,
  `languages.ex`, `translations.ex`, `subdivisions.ex` now specced (`unions.ex`,
  `random.ex` already were). New `Subdivision.t` type.
- **`Country.t` tightening** - `alpha2`/`alpha3`/`name` are now required `String.t()`.
  **Discovery:** dialyzer then flagged three genuinely wrong type fields, corrected
  against the data: `number` is a `String.t()` (`'004'`), `postal_code` is a `boolean()`,
  `international_prefix` is `String.t() | integer()` (3 YAML files have unquoted `09`).
  Root fix would be quoting those YAML values - left as data-level follow-up.
- **`Subdivisions.all/1` symmetry** - accepts an alpha2 string or a `%Country{}`.
- **CI** - `.github/workflows/ci.yml` (Elixir 1.18/OTP 27, runs `mix test` + `mix precommit`);
  legacy `.travis.yml` (pinned Elixir 1.9.1!) removed.
- **Trivia** - no-op `Map.new/1` in `languages.ex` removed. `atomize_keys/1` duplication
  kept deliberately (matches the existing per-loader module pattern).

## Deliberately not done

- `Currencies.format_cents/2` (integer minor units) - was a "consider" item;
  `format/3` is now documented as display-only instead. Revisit if money formatting
  becomes a real use case.
- Data-level roadmap items (new translation locales, 26 missing subdivision datasets,
  additional unions, time zones, borders) - untouched, still tracked in
  `dev_docs/2026-03-28_roadmap.md`.
- Quoting the 3 unquoted `international_prefix` YAML values (see above).

## Final verification (2026-07-17)

| Check | Before | After |
|-------|--------|-------|
| `mix test` | 96 doctests, 148 tests, 0 failures | **121 doctests, 159 tests, 0 failures** |
| `mix format --check-formatted` | clean | clean |
| `mix credo --strict` | clean (119 mods/funs) | clean (123 mods/funs) |
| `mix dialyzer` | 0 errors (stale PLT) | **0 errors (fresh PLT from scratch)** |
| `mix precommit` (incl. `hex.audit`, `--warnings-as-errors`) | n/a | **pass** |
| `@external_resource` chain | countries/unions/subdivisions untracked | all 3 verified recompiling on content edit |

## Files changed

- **New:** `lib/subdivision_loader.ex`, `test/translations_test.exs`,
  `.github/workflows/ci.yml`
- **Modified:** `lib/countries.ex`, `lib/country.ex`, `lib/currencies.ex`,
  `lib/languages.ex`, `lib/locale.ex`, `lib/loader.ex`, `lib/union_loader.ex`,
  `lib/random.ex`, `lib/subdivision.ex`, `lib/subdivisions.ex`, `lib/translations.ex`,
  `mix.exs`, `README.md`, `CHANGELOG.md` (Unreleased section), `dev_docs/TODO.md`,
  `dev_docs/2026-03-28_roadmap.md`, `test/languages_test.exs`,
  `test/subdivisions_test.exs`
- **Removed:** `.travis.yml`
