# Number, date and currency formats

`decimal_separator`, `thousands_separator`, `date_format`, `currency_format` and
`number_format_locale` in `priv/data/countries/{CC}.yaml` are generated from
[Unicode CLDR](https://github.com/unicode-org/cldr-json) by `build_formats.py`. Re-run it to move to a newer CLDR
release (change `CLDR` in the script). It rewrites the five keys at the end of every country file.

## Regenerate

```bash
G=$(mktemp -d)   # downloaded CLDR files are untrusted input: keep them outside the repo
mix run -e 'File.write!("'$G'/langs.json", JSON.encode!(Map.new(BeamLabCountries.all(), &{&1.alpha2, &1.languages_official || []})))'
python3 -I dev_docs/formats/build_formats.py $G/cldr priv/data/countries $G/langs.json
```

(`mkdir $G/cldr` first.) The script prints the countries that fell back to `en-001`.

## Rules

- CLDR is organised by locale, not country. A country uses the locale of its first official language:
  `<lang>-<CC>` if CLDR has it (`de-CH`, `nl-BE`), else the bare `<lang>` locale (`de` for Germany,
  which is CLDR's `de-DE`), else `en-001` (Antarctica, Bouvet Island, Maldives: no official language CLDR covers).
- Countries with several languages get one format; the Belgian French or Swiss Italian conventions differ.
- Separators and the currency pattern use CLDR's `latn` number system, so `0-9` digits, also for Arabic locales.
- `date_format` is the CLDR *short* Gregorian pattern: `d`/`dd` -> `D`/`DD`, `M`/`MM` -> `M`/`MM`,
  `y`/`yy` -> `YYYY`. Padding is CLDR's (`M/D/YYYY` in the US). Era markers and bidi marks are dropped.
  Countries whose official calendar is not Gregorian (Thailand, Iran, Saudi Arabia) still get Gregorian.
- `currency_format` is the positive part of the CLDR standard currency pattern with `¤` -> `{{symbol}}` and the
  number part -> `{{amount}}`. Negative and accounting forms are not stored.
- Not covered: digit grouping other than thousands (India's lakh grouping `12,34,567`), minimum grouping digits
  (Spanish `1234` vs `12.345`), percent and other number patterns.
