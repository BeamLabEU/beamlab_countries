"""Builds priv/data/cities/{CC}.json from GeoNames dumps (CC BY 4.0, https://www.geonames.org).

Usage: python3 -I build_cities.py <geonames_dir> <out_dir>

<geonames_dir> must contain (all from https://download.geonames.org/export/dump/):
  cities1000.zip              unzipped on the fly
  alt/{CC}.zip                from /alternatenames/{CC}.zip, one per country
  langs.json   {"EE": ["et"], ...}  Country.languages_official
  us_ids.json  ["AK", "AL", ...]    Subdivisions.all("US") ids
  zones.json   {"EE": ["Europe/Tallinn"], ...}  Country.timezones
(langs/us_ids/zones are produced with `mix run -e` from BeamLabCountries, see dev_docs/cities.md.)

Selection: top 10 populated places per country by population (places within 12 km of a larger
one are skipped, the capital is always included); for US and CA also the top 5 per state/province.
"""
import csv, io, json, os, sys, unicodedata, zipfile, collections
G, OUT = sys.argv[1], sys.argv[2]
LOCALES = "ar cs de en es et fr hi id it ja ko nl pl pt ro ru sv th tr uk vi zh".split()
# GeoNames language tags accepted per locale (first match wins)
TAGS = {l: [l] for l in LOCALES}
TAGS["zh"] = ["zh-CN", "zh-Hans", "zh"]
TAGS["pt"] = ["pt", "pt-PT"]
CA = {"01":"AB","02":"BC","03":"MB","04":"NB","05":"NL","07":"NS","08":"ON","09":"PE","10":"QC","11":"SK","12":"YT","13":"NT","14":"NU"}
KEEP = {"PPL", "PPLA", "PPLA2", "PPLA3", "PPLA4", "PPLA5", "PPLC", "PPLG"}
# GeoNames files these as ordinary places, or has a bogus population for them
EXCLUDE = {5110302, 5133273, 5125771, 5110266, 5139568, 2780180}
# Hand-picked translations that win over GeoNames: {geonames_id: {locale: name}}
NAME_OVERRIDES = {
    588409: {"ru": "Таллинн"},  # Tallinn: the spelling Estonia uses, rather than the Russian-norm "Таллин"
}
MIN_SIGNAL = 4     # alternate-name rows; suburbs/neighbourhoods and bogus entries have few
MIN_POP_FOR_SIGNAL = 30000
COLLAPSE_KM = 12    # drop non-capital places this close to a larger one: suburbs, communes, districts

def km(a, b):
    from math import radians, sin, cos, asin, sqrt
    dlat, dlng = radians(b["lat"] - a["lat"]), radians(b["lng"] - a["lng"])
    h = sin(dlat / 2) ** 2 + cos(radians(a["lat"])) * cos(radians(b["lat"])) * sin(dlng / 2) ** 2
    return 12742 * asin(sqrt(h))

langs = json.load(open(f"{G}/langs.json"))
zones = json.load(open(f"{G}/zones.json"))
us_ids = set(json.load(open(f"{G}/us_ids.json")))

cities = collections.defaultdict(list)
z = zipfile.ZipFile(f"{G}/cities1000.zip")
for r in csv.reader(io.TextIOWrapper(z.open("cities1000.txt"), encoding="utf-8"), delimiter="\t", quoting=csv.QUOTE_NONE):
    if r[7] not in KEEP or r[8] not in langs or int(r[0]) in EXCLUDE: continue
    cities[r[8]].append(dict(id=int(r[0]), name=r[1], lat=float(r[4]), lng=float(r[5]), code=r[7], admin1=r[10],
                             pop=int(r[14] or 0), tz=r[17], cc=r[8]))

def subdivision(c):
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
    cands = [c for c in cands if not abbreviation(c[1]) and script_ok(c[1], locale)]
    good = [c for c in cands if not c[3]] or cands
    pref = [c for c in good if c[2]]
    if pref: return min(pref, key=lambda c: c[0])[1]
    sane = [c for c in good if "_" not in c[1] and len(c[1]) >= 2]
    if not sane: return None
    if english in {c[1] for c in sane}: return english
    return min(sane, key=lambda c: (len(c[1]), c[0]))[1]

total = 0
report = []
for cc, lst in sorted(cities.items()):
    ids = {c["id"] for c in lst}
    official = langs.get(cc, [])
    want = set(official) | {t for l in LOCALES for t in TAGS[l]}
    names = collections.defaultdict(lambda: collections.defaultdict(list))
    rows = collections.Counter()
    path = f"{G}/alt/{cc}.zip"
    if os.path.exists(path):
        with zipfile.ZipFile(path).open(f"{cc}.txt") as f:
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
    if cc in ("US", "CA"):
        by_sub = collections.defaultdict(list)
        for c in lst:
            s = subdivision(c)
            if s: by_sub[s].append(c)
        for sl in by_sub.values():
            for c in sl[:5]:
                if c not in pick: pick.append(c)

    result = []
    for c in sorted(pick, key=lambda c: (-c["pop"], c["name"])):
        n = names.get(c["id"], {})
        en = [x for x in n.get("en", []) if x[2]]
        name = min(en, key=lambda x: x[0])[1] if en else c["name"]
        native = name
        for l in official:
            if l in n:
                v = pick_name(n[l], name)
                if v: native = v; break
        tr = {}
        for l in LOCALES:
            cands = next((n[t] for t in TAGS[l] if t in n), [])
            if cands:
                v = pick_name(cands, name, l)
                if v and v != name: tr[l] = v
        tr.update(NAME_OVERRIDES.get(c["id"], {}))
        d = {"id": c["id"], "name": name, "native_name": native}
        if tr: d["translations"] = dict(sorted(tr.items()))
        tz = c["tz"]
        # tzdb merged some zones into links; map to the country's only canonical zone
        if tz not in zones[cc] and len(zones[cc]) == 1: tz = zones[cc][0]
        d.update({"subdivision": subdivision(c), "population": c["pop"], "latitude": c["lat"], "longitude": c["lng"],
                  "timezone": tz, "capital": bool(caps) and c is caps[0]})
        result.append(d)
    os.makedirs(OUT, exist_ok=True)
    with open(f"{OUT}/{cc}.json", "w", encoding="utf-8") as f:
        f.write("[\n" + ",\n".join("  " + json.dumps(d, ensure_ascii=False, separators=(",", ":")) for d in result) + "\n]\n")
    total += len(result)
    if cc not in ("US", "CA"):
        report.append(cc + ": " + ", ".join(d["name"] + ("*" if d["capital"] else "") for d in result))
print("countries", len(cities), "cities", total)
open(f"{OUT}/../report.txt", "w").write("\n".join(report))
