# City data

`priv/data/cities/{CC}.json` is generated from [GeoNames](https://www.geonames.org) dumps
(CC BY 4.0) by `build_cities.py`. Re-run it to refresh populations or add locales.

## Regenerate

```bash
G=$(mktemp -d) && mkdir $G/alt && cd $G
B=https://download.geonames.org/export/dump
curl -O $B/cities1000.zip
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
- Per country: the 10 largest by population, then the capital if missing. A place closer than
  12 km to a larger one is skipped (suburbs, communes and districts, so the list reads like
  metro areas rather than 10 neighbourhoods of one city). The capital is exempt.
- US and CA: additionally the 5 largest places per state/province (no 12 km rule), with the
  `subdivision` mapped to our IDs (GeoNames CA admin1 codes are numeric, see `CA` in the script).
- Places with at least 30,000 inhabitants but fewer than 4 alternate-name rows are dropped:
  GeoNames has bogus populations for obscure villages and neighbourhoods.
- A few places are excluded by ID (`EXCLUDE`): NYC boroughs and one village with a bogus population.

## Names

- `name`: GeoNames' preferred English name, otherwise its primary name.
- `native_name`: first official language of the country with a usable name, otherwise `name`.
- `translations`: only for the 23 locales of `Translations`, only when different from `name`.
  A name flagged "preferred" wins. Unflagged names are unreliable (region names, spelling variants,
  ids such as `Rakvere_vald`), so ids with `_` and abbreviations (`СПб`) are dropped and the shortest
  remaining name is used, with the English name winning when it is a candidate. `zh` prefers simplified
  (`zh-CN`/`zh-Hans`) but falls back to untagged `zh`, which is sometimes traditional;
  `pt` is European Portuguese like the rest of the data.
  Names in the wrong script for the locale (Cyrillic `ro`, Thai `ar`) and mixed-script names
  (`Тарrafal`) are rejected before picking, see `script_ok`. Hand-picked fixes go in `NAME_OVERRIDES`.

## Known limits

- Populations are for the city proper, whatever GeoNames has; they can be outdated.
- Quality drops for tiny countries and territories, where GeoNames only lists villages.
