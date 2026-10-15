"""Builds priv/data/cities/{CC}.json from GeoNames dumps (CC BY 4.0, https://www.geonames.org).

Usage: python3 -I build_cities.py <geonames_dir> <out_dir>

<geonames_dir> must contain (all from https://download.geonames.org/export/dump/):
  cities1000.zip              unzipped on the fly
  CA.zip                      full Canadian dump, including small northern settlements
  alt/{CC}.zip                from /alternatenames/{CC}.zip, one per country
  langs.json   {"EE": ["et"], ...}  Country.languages_official
  us_ids.json  ["AK", "AL", ...]    Subdivisions.all("US") ids
  zones.json   {"EE": ["Europe/Tallinn"], ...}  Country.timezones
(langs/us_ids/zones are produced with `mix run -e` from BeamLabCountries, see README.md here.)

Selection: top 10 populated places per country by population (places within 12 km of a larger
one are skipped, the capital is always included); also the top 10 per US state and
at least 10 populated places per Canadian province/territory.
"""
import collections
import csv
import io
import json
import os
import unicodedata
import zipfile
LOCALES = "ar cs de en es et fr hi id it ja ko nl pl pt ro ru sv th tr uk vi zh".split()
# GeoNames language tags accepted per locale (first match wins)
TAGS = {l: [l] for l in LOCALES}
TAGS["zh"] = ["zh-CN", "zh-Hans", "zh"]
TAGS["pt"] = ["pt", "pt-PT"]
CA = {"01":"AB","02":"BC","03":"MB","04":"NB","05":"NL","07":"NS","08":"ON","09":"PE","10":"QC","11":"SK","12":"YT","13":"NT","14":"NU"}
KEEP = {"PPL", "PPLA", "PPLA2", "PPLA3", "PPLA4", "PPLA5", "PPLC", "PPLG"}
# GeoNames files these as ordinary places, or has a bogus population for them
EXCLUDE = {5110302, 5133273, 5125771, 5110266, 5139568, 2780180}
# Keep previously shipped places when newly included communities move them out of the top ten.
INCLUDE = {5927708}  # Coral Harbour, Nunavut
# Hand-picked translations that win over GeoNames: {geonames_id: {locale: name}}
NAME_OVERRIDES = {
    588409: {"ru": "Таллинн"},  # Tallinn: the spelling Estonia uses, rather than the Russian-norm "Таллин"
    2990969: {"uk": "Нант"},  # Nantes: missing from the GeoNames Ukrainian names
}
MIN_SIGNAL = 4     # alternate-name rows; suburbs/neighbourhoods and bogus entries have few
MIN_POP_FOR_SIGNAL = 30000
COLLAPSE_KM = 12    # drop non-capital places this close to a larger one: suburbs, communes, districts
SUBDIVISION_LIMITS = {"US": 10, "CA": 10}

def load_places(archive_path, member, country_codes, places, country=None):
    with zipfile.ZipFile(archive_path) as archive:
        with archive.open(member) as f:
            for r in csv.reader(io.TextIOWrapper(f, encoding="utf-8"), delimiter="\t", quoting=csv.QUOTE_NONE):
                cc = r[8]
                if cc not in country_codes or (country and cc != country): continue
                # Canadian communities such as Rankin Inlet are classified PPLL.
                if r[7] not in KEEP and not (cc == "CA" and r[7] == "PPLL"): continue
                gid = int(r[0])
                if gid in EXCLUDE or gid in places: continue
                places[gid] = dict(id=gid, name=r[1], lat=float(r[4]), lng=float(r[5]), code=r[7],
                                   admin1=r[10], pop=int(r[14] or 0), tz=r[17], cc=cc)

def km(a, b):
    from math import radians, sin, cos, asin, sqrt
    dlat, dlng = radians(b["lat"] - a["lat"]), radians(b["lng"] - a["lng"])
    h = sin(dlat / 2) ** 2 + cos(radians(a["lat"])) * cos(radians(b["lat"])) * sin(dlng / 2) ** 2
    return 12742 * asin(sqrt(min(1.0, h)))

def subdivision(c, us_ids):
    if c["cc"] == "US" and c["admin1"] in us_ids: return c["admin1"]
    if c["cc"] == "CA": return CA.get(c["admin1"])
    return None

def abbreviation(name):
    # "СПб", "NYC": short and starting with two capitals
    return len(name) <= 4 and name[:2].isupper()

LATIN = {"LATIN", "MODIFIER"}  # MODIFIER: letters like ʻ in Uzbek "Fargʻona"
SCRIPTS = {l: LATIN for l in "cs de en es et fr id it nl pl pt ro sv tr vi".split()}
SCRIPTS.update(ar={"ARABIC"}, hi={"DEVANAGARI"}, ko={"HANGUL"}, ru={"CYRILLIC"}, uk={"CYRILLIC"},
               th={"THAI"}, ja={"CJK", "HIRAGANA", "KATAKANA", "KATAKANA-HIRAGANA"}, zh={"CJK"})

def scripts(name):
    out = set()
    for ch in name:
        if ch.isalpha():
            try: out.add(unicodedata.name(ch).split()[0])
            except ValueError: pass
    return out

def script_ok(name, locale):
    """GeoNames has names in the wrong script (Cyrillic "ro", Thai "ar") and mixed ones ("Тарrafal").
    Without a locale (native names, any script), only mixed-script names are rejected."""
    s = scripts(name)
    if locale in SCRIPTS: return s <= SCRIPTS[locale]
    return len(s - LATIN) == 0 or not s & LATIN

def pick_name(cands, english=None, locale=None):
    """cands: (altid, name, preferred, short). A name flagged "preferred" wins. Unflagged names are
    unreliable (GeoNames mixes in region names, spelling variants and ids like "Rakvere_vald"), so
    drop obviously bad ones and take the shortest, which is usually the plain city name
    ("Salzburg" rather than "Salzburgi liidumaa"); the English name wins when it is a candidate."""
    cands = [c for c in cands if len(c[1]) >= 2 and "_" not in c[1]
             and not abbreviation(c[1]) and script_ok(c[1], locale)]
    pref = [c for c in cands if c[2]]
    if pref: return min(pref, key=lambda c: c[0])[1]
    sane = [c for c in cands if not c[3]] or cands
    if not sane: return None
    if english in {c[1] for c in sane}: return english
    return min(sane, key=lambda c: (len(c[1]), c[0]))[1]

def translated_name(names, locale, english):
    # A tag can exist but contain only unusable names; keep trying its fallbacks.
    for tag in TAGS[locale]:
        name = pick_name(names.get(tag, []), english, locale)
        if name: return name
    return None

def build(geonames_dir, out_dir):
    G, OUT = geonames_dir, out_dir
    with open(f"{G}/langs.json", encoding="utf-8") as f:
        langs = json.load(f)
    with open(f"{G}/zones.json", encoding="utf-8") as f:
        zones = json.load(f)
    with open(f"{G}/us_ids.json", encoding="utf-8") as f:
        us_ids = set(json.load(f))

    places = {}
    load_places(f"{G}/cities1000.zip", "cities1000.txt", langs, places)
    if "CA" in langs:
        # Preserve shared IDs from cities1000; supplement its population cutoff.
        load_places(f"{G}/CA.zip", "CA.txt", langs, places, country="CA")
    cities = collections.defaultdict(list)
    for city in places.values():
        cities[city["cc"]].append(city)

    # Missing names would silently discard large cities through MIN_SIGNAL.
    missing = sorted(cc for cc in cities if not os.path.isfile(f"{G}/alt/{cc}.zip"))
    if missing:
        raise FileNotFoundError("Missing alternate-name archives: " + ", ".join(missing))

    os.makedirs(OUT, exist_ok=True)
    total = 0
    report = []
    for cc, lst in sorted(cities.items()):
        ids = {c["id"] for c in lst}
        official = langs.get(cc, [])
        want = set(official) | {t for l in LOCALES for t in TAGS[l]}
        names = collections.defaultdict(lambda: collections.defaultdict(list))
        rows = collections.Counter()
        path = f"{G}/alt/{cc}.zip"
        with zipfile.ZipFile(path) as archive:
            with archive.open(f"{cc}.txt") as f:
                for r in csv.reader(io.TextIOWrapper(f, encoding="utf-8"), delimiter="\t", quoting=csv.QUOTE_NONE):
                    if len(r) < 8: continue
                    try: gid = int(r[1])
                    except ValueError: continue
                    if gid not in ids: continue
                    rows[gid] += 1
                    if r[2] not in want or r[6] == "1" or r[7] == "1": continue
                    names[gid][r[2]].append((int(r[0]), r[3], r[4] == "1", r[5] == "1"))

        lst = [c for c in lst if c["code"] == "PPLC" or c["pop"] < MIN_POP_FOR_SIGNAL or rows[c["id"]] >= MIN_SIGNAL]
        lst.sort(key=lambda c: (-c["pop"], c["name"]))
        caps = [c for c in lst if c["code"] == "PPLC"]
        pick = []
        for c in lst:
            if len(pick) == 10: break
            if c is not (caps[0] if caps else None) and any(km(c, p) < COLLAPSE_KM for p in pick): continue
            pick.append(c)
        if caps and caps[0] not in pick: pick.append(caps[0])
        if cc in SUBDIVISION_LIMITS:
            by_sub = collections.defaultdict(list)
            for c in lst:
                s = subdivision(c, us_ids)
                if s: by_sub[s].append(c)
            if cc == "CA":
                shortages = {s: len(by_sub[s]) for s in CA.values() if len(by_sub[s]) < SUBDIVISION_LIMITS[cc]}
                if shortages:
                    raise ValueError(f"Canada needs at least 10 populated places per subdivision; found {shortages}")
            for sl in by_sub.values():
                for c in sl[:SUBDIVISION_LIMITS[cc]]:
                    if c not in pick: pick.append(c)

        for c in lst:
            if c["id"] in INCLUDE and c not in pick: pick.append(c)

        result = []
        for c in sorted(pick, key=lambda c: (-c["pop"], c["name"])):
            n = names.get(c["id"], {})
            en = [x for x in n.get("en", []) if x[2]]
            name = pick_name(en, locale="en") or c["name"]
            native = name
            for l in official:
                if l in n:
                    v = pick_name(n[l], name, l)
                    if v:
                        native = name if l == "en" else v
                        break
            tr = {}
            for l in LOCALES:
                if l == "en": continue
                v = translated_name(n, l, name)
                if v and v != name: tr[l] = v
            tr.update(NAME_OVERRIDES.get(c["id"], {}))
            tr = {l: value for l, value in tr.items() if l != "en" and value != name}
            d = {"id": c["id"], "name": name, "native_name": native}
            if tr: d["translations"] = dict(sorted(tr.items()))
            tz = c["tz"]
            # tzdb merged some zones into links; map to the country's only canonical zone
            if tz not in zones[cc] and len(zones[cc]) == 1: tz = zones[cc][0]
            d.update({"subdivision": subdivision(c, us_ids), "population": c["pop"], "latitude": c["lat"], "longitude": c["lng"],
                      "timezone": tz, "capital": bool(caps) and c is caps[0]})
            result.append(d)
        with open(f"{OUT}/{cc}.json", "w", encoding="utf-8") as f:
            f.write("[\n" + ",\n".join("  " + json.dumps(d, ensure_ascii=False, separators=(",", ":")) for d in result) + "\n]\n")
        total += len(result)
        if cc not in ("US", "CA"):
            report.append(cc + ": " + ", ".join(d["name"] + ("*" if d["capital"] else "") for d in result))
    print("countries", len(cities), "cities", total)
    with open(f"{OUT}/report.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(report))


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("geonames_dir")
    parser.add_argument("out_dir")
    args = parser.parse_args()
    build(args.geonames_dir, args.out_dir)
