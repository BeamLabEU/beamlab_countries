# Fix: Locale & Language Data Gaps Across All Countries

**Date:** 2026-02-16
**Triggered by:** Belarus (BY) audit during `language_locales` work

---

## Problem

An audit of the Belarus data revealed two systemic gaps that affected the entire dataset, not just one country.

### Gap 1: 54 spoken languages had no locale entry

Out of 184 languages in `languages.json`, only 86 had a matching entry in `locales.json`. The remaining languages (like Greek `el`, Hausa `ha`, Zulu `zu`) were invisible to any locale-based filtering or lookup.

This meant `BeamLabCountries.Languages.get_locale("el")` returned `nil` even though Greek is a real, widely-spoken language with a clear primary region (Greece). Same for 53 others.

### Gap 2: 247 countries had incomplete or missing `language_locales` mapping

The `language_locales` field was introduced in v1.0.4 to map base language codes to their regional variants (e.g., `en` -> `en-GB` or `en-US`). However, only a handful of countries (BY, CA, and a few others) had this field populated.

Two sub-problems:

1. **Multi-variant languages only covered ~167 countries.** The 6 languages with regional variants (en, fr, de, es, pt, zh) were only mapped where the field already existed. The remaining countries that speak these languages had no mapping at all.

2. **Single-variant languages were completely ignored.** Languages like Norwegian `nb`/`nn`, Greek `el`, Arabic `ar`, Persian `fa`, etc. that have valid locale entries were never included in `language_locales`. For example, Norway only had `%{en: "en-GB"}` but was missing `nb: "nb"` and `nn: "nn"`. Countries that speak *only* single-variant languages (like Afghanistan, Mongolia, Iran, Georgia) had no `language_locales` at all.

Without this, consumers couldn't resolve which locale variant applies for any given country-language pair.

---

## Findings

### The 54 missing locales

These are all ISO 639-1 codes present in `languages.json` and referenced by country YAML files, but absent from `locales.json`:

```
af/ZA  ay/BO  bi/VU  ch/GU  dv/MV  dz/BT  el/GR  ff/GN  fj/FJ
fo/FO  gn/PY  gv/IM  ha/NG  ht/HT  ig/NG  jv/ID  kg/CD  kl/GL
ku/TR  la/VA  lb/LU  ln/CD  lu/CD  mg/MG  mh/MH  mi/NZ  na/NR
nb/NO  nd/ZW  nn/NO  nr/ZA  ny/MW  ps/AF  qu/BO  rm/CH  rn/BI
rw/RW  sd/PK  sg/CF  sm/WS  sn/ZW  so/SO  ss/SZ  st/LS  tg/TJ
ti/ER  tn/BW  to/TO  ts/ZA  tt/RU  ve/ZA  xh/ZA  yo/NG  zu/ZA
```

Each uses the base code as the key (e.g., `"el"`, not `"el-GR"`), consistent with existing single-variant locales like `"bg"`, `"ru"`, `"uk"`.

### 5 non-standard codes were skipped

Five language codes found in some country files (mostly Nepal and Philippines) don't exist in `languages.json`:

| Code | Language | Note |
|------|----------|------|
| `bho` | Bhojpuri | ISO 639-3, not 639-1 |
| `ceb` | Cebuano | ISO 639-3, not 639-1 |
| `mai` | Maithili | ISO 639-3, not 639-1 |
| `new` | Newari | ISO 639-3, not 639-1 |
| `urd` | Urdu (alt) | Duplicate of `ur` (639-1) |

These are out of scope for this fix. See "Follow-up work" below.

### Locale variant mapping rules

For the 6 multi-variant languages, the following rules determine which regional variant applies to a country:

**English (`en`)**
| Variant | Applies to |
|---------|------------|
| `en-CA` | Canada only |
| `en-AU` | Australia, New Zealand |
| `en-US` | Americas (except CA), Japan, South Korea, Taiwan |
| `en-GB` | Default -- Europe, Africa, Asia, Oceania, Middle East |

**French (`fr`)**
| Variant | Applies to |
|---------|------------|
| `fr-CA` | Canada only |
| `fr-FR` | Default -- everywhere else |

**German (`de`)**
| Variant | Applies to |
|---------|------------|
| `de-AT` | Austria only |
| `de-CH` | Switzerland only |
| `de-DE` | Default -- everywhere else |

**Spanish (`es`)**
| Variant | Applies to |
|---------|------------|
| `es-AR` | Argentina only |
| `es-MX` | Mexico, US, Central America, Caribbean |
| `es-ES` | Europe |
| `es-CO` | Default -- rest of Americas and elsewhere |

**Portuguese (`pt`)**
| Variant | Applies to |
|---------|------------|
| `pt-BR` | Brazil, rest of Americas |
| `pt-PT` | Default -- Europe, Africa, Asia |

**Chinese (`zh`)**
| Variant | Applies to |
|---------|------------|
| `zh-TW` | Taiwan only |
| `zh-CN` | Default -- everywhere else |

**Single-variant languages**

All other languages that have locale entries (like `nb`, `nn`, `el`, `ar`, etc.) map to themselves:
```yaml
language_locales:
  nb: nb    # Norwegian Bokmal
  nn: nn    # Norwegian Nynorsk
  el: el    # Greek
```

---

## What was done

### Files modified

| Change | Count | Description |
|--------|-------|-------------|
| `priv/data/locales.json` | 1 file | Added 54 locale entries (86 -> 140 total) |
| `priv/data/countries/*.yaml` | 247 files | Added `language_locales` block before `geo:` |
| `lib/languages.ex` | 1 file | Updated locale count in doctest (86 -> 140) |
| `test/countries_test.exs` | 1 file | Added 5 tests for `language_locales` field |

### Verification

- `mix compile --force` -- clean compilation
- `mix test` -- 93 doctests, 125 tests, 0 failures
- `mix credo --strict` -- no issues

All `language_locales` mappings validated:
- 247 countries have `language_locales` populated
- 3 countries have no spoken languages defined (AN, AQ, BV)
- 0 invalid locale references -- every value in every `language_locales` map is a valid locale code

### Spot check results

```elixir
# Locale count
BeamLabCountries.Languages.locale_count()           #=> 140

# Newly added locale works
BeamLabCountries.Languages.get_locale("el")          #=> %Locale{name: "Greek (modern)", region_code: "GR"}

# Multi-variant languages resolve to correct regional variant
BeamLabCountries.get("KE").language_locales           #=> %{en: "en-GB", sw: "sw"}
BeamLabCountries.get("JM").language_locales           #=> %{en: "en-US"}
BeamLabCountries.get("SN").language_locales           #=> %{fr: "fr-FR"}
BeamLabCountries.get("MZ").language_locales           #=> %{pt: "pt-PT", sw: "sw"}
BeamLabCountries.get("GT").language_locales           #=> %{es: "es-MX"}
BeamLabCountries.get("HK").language_locales           #=> %{en: "en-GB", zh: "zh-CN"}
BeamLabCountries.get("LU").language_locales           #=> %{de: "de-DE", en: "en-GB", fr: "fr-FR", lb: "lb", pt: "pt-PT"}

# Single-variant languages included alongside multi-variant
BeamLabCountries.get("NO").language_locales           #=> %{en: "en-GB", nb: "nb", nn: "nn"}
BeamLabCountries.get("ZA").language_locales           #=> %{af: "af", en: "en-GB", nr: "nr", ss: "ss", st: "st", tn: "tn", ts: "ts", ve: "ve", xh: "xh", zu: "zu"}
BeamLabCountries.get("GR").language_locales           #=> %{de: "de-DE", el: "el", en: "en-GB", fr: "fr-FR"}
BeamLabCountries.get("IN").language_locales           #=> %{bn: "bn", en: "en-GB", hi: "hi", mr: "mr", ta: "ta", te: "te"}

# Single-variant only countries (no multi-variant languages spoken)
BeamLabCountries.get("AF").language_locales           #=> %{ps: "ps", tk: "tk", uz: "uz"}
BeamLabCountries.get("MN").language_locales           #=> %{mn: "mn"}
BeamLabCountries.get("IR").language_locales           #=> %{fa: "fa"}
BeamLabCountries.get("GE").language_locales           #=> %{ka: "ka"}
```

---

## Countries without `language_locales`

Only 3 countries have no `language_locales` -- all because they have no spoken languages defined:

```
AN  (Netherlands Antilles - dissolved)
AQ  (Antarctica)
BV  (Bouvet Island)
```

---

## Follow-up work

### 1. ISO 639-3 codes in country data

Five language codes in country YAML files don't exist in `languages.json` (which only covers ISO 639-1). Options:

- **Add them to `languages.json`** as extended entries (requires a policy decision on 639-3 support)
- **Map them to 639-1 equivalents** where possible (`urd` -> `ur`)
- **Leave as-is** and document as a known limitation

### 2. Arabic regional variants

Arabic (`ar`) is spoken across 20+ countries with significant regional variation (Egyptian, Gulf, Levantine, Maghrebi). Currently treated as a single-variant language mapping to itself. A future pass could add `ar-EG`, `ar-SA`, `ar-MA`, etc.

### 3. Dutch regional variants

Dutch is spoken in the Netherlands, Belgium (Flemish), and Suriname. Currently single-variant. Could benefit from `nl-NL`, `nl-BE`.

### 4. Malay/Indonesian overlap

`ms` (Malay) and `id` (Indonesian) are closely related. Some countries list both. No action needed but worth noting for consumers doing language deduplication.

### 5. Country-specific edge cases

The multi-variant mapping rules are based on broad geographic patterns. Some countries may warrant manual overrides:

- **Philippines (PH)** -- currently maps to `en-GB` (Asia default), but historically uses American English due to US colonial history. May warrant `en-US`.
- **Liberia (LR)** -- currently maps to `en-GB` (Africa default), but was founded by American settlers. May warrant `en-US`.
- **Israel (IL)** -- currently maps to `en-GB` (Asia default), but American English is commonly used alongside British English.

These edge cases require local knowledge to resolve and are left for a future review.
