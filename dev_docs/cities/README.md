# City data

`priv/data/cities/{CC}.json` is generated from [GeoNames](https://www.geonames.org) dumps
(CC BY 4.0) by `build_cities.py`. Re-run it to refresh populations or add locales.

## Regenerate

```bash
G=$(mktemp -d) && mkdir $G/alt && cd $G
B=https://download.geonames.org/export/dump
curl -O $B/cities1000.zip
curl -O $B/CA.zip
for cc in $(sed -n 's/^- //p' /path/to/priv/data/countries.yaml); do
  curl -sf -o alt/$cc.zip $B/alternatenames/$cc.zip
done

cd /path/to/beamlab_countries
mix run -e 'File.write!("'$G'/langs.json", JSON.encode!(Map.new(BeamLabCountries.all(), &{&1.alpha2, &1.languages_official || []})))'
mix run -e 'File.write!("'$G'/us_ids.json", JSON.encode!(Enum.map(BeamLabCountries.Subdivisions.all("US"), & &1.id)))'
mix run -e 'File.write!("'$G'/zones.json", JSON.encode!(Map.new(BeamLabCountries.all(), &{&1.alpha2, &1.timezones})))'

python3 -I dev_docs/cities/build_cities.py $G /tmp/cities_out && cp /tmp/cities_out/*.json priv/data/cities/
```

Downloaded files are untrusted input: keep them outside the repo, as above.

## Selection rules

- Populated places only (`PPL`, `PPLA*`, `PPLC`, `PPLG`) from `cities1000`.
  Canada is supplemented with the full `CA.zip` dump and its `PPLL` (populated locality)
  entries, including northern communities such as Rankin Inlet. Existing IDs from
  `cities1000` take precedence when the archives overlap.
- Per country: the 10 largest by population, then the capital if missing. A place closer than
  12 km to a larger one is skipped (suburbs, communes and districts, so the list reads like
  metro areas rather than 10 neighbourhoods of one city). The capital is exempt.
- US and CA: additionally the 10 largest places per state/province/territory (no 12 km rule), with the
  `subdivision` mapped to our IDs (GeoNames CA admin1 codes are numeric, see `CA` in the script).
  Generation fails if a Canadian province or territory has fewer than ten eligible places;
  tests also enforce ten entries in every US state. `INCLUDE` preserves previously shipped
  Coral Harbour alongside Nunavut's new top ten. Current coverage: 510 US places and 131 Canadian places.
- Places with at least 30,000 inhabitants but fewer than 4 alternate-name rows are dropped:
  GeoNames has bogus populations for obscure villages and neighbourhoods.
- A few places are excluded by ID (`EXCLUDE`): NYC boroughs and one village with a bogus population.

## Names

- `name`: GeoNames' preferred English name, otherwise its primary name.
- `native_name`: first official language of the country with a usable name, otherwise `name`.
- `translations`: only for the 23 locales of `Translations`, only when different from `name`.
  English lookups always use the canonical `name`, so `en` is omitted from `translations`.
  A name flagged "preferred" wins, including preferred short names. Unflagged names are unreliable (region names, spelling variants,
  ids such as `Rakvere_vald`), so ids with `_` and abbreviations (`СПб`) are dropped and the shortest
  remaining name is used, with the English name winning when it is a candidate. `zh` prefers simplified
  (`zh-CN`/`zh-Hans`) but falls back to untagged `zh`, which is sometimes traditional;
  `pt` is European Portuguese like the rest of the data.
  If a preferred language tag has no usable name, its fallback tags are tried in order.
  Names in the wrong script for the locale (Cyrillic `ro`, Thai `ar`) and mixed-script names
  (`Тарrafal`) are rejected before picking, see `script_ok`. Hand-picked fixes go in `NAME_OVERRIDES`.

## Known limits

- Populations use GeoNames' varying geographic boundaries and dates; they can be outdated.
- Quality drops for tiny countries and territories, where GeoNames only lists villages.
- Coverage is 244 countries and territories. Capital flags follow GeoNames' `PPLC` feature
  code; some countries have no such entry, and seats of government (`PPLG`) are not marked capitals.

Missing alternate-name archives stop generation before writing output: otherwise the
alternate-name quality filter would silently remove large cities. The review report is
written to `<out_dir>/report.txt`.

Run the offline generator regressions with:

```bash
python3 -I dev_docs/cities/test_build_cities.py
```
