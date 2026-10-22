"""Adds number, date and currency format fields to priv/data/countries/{CC}.yaml from Unicode CLDR.

Usage: python3 -I build_formats.py <cldr_dir> <countries_dir> <langs.json>

<cldr_dir>      cache for the downloaded CLDR JSON files (outside the repo)
<countries_dir> priv/data/countries
<langs.json>    {"EE": ["et"], ...}  Country.languages_official, produced with `mix run -e`, see README.md here

For each country the first official language that CLDR has a `<lang>-<CC>` locale for decides the
formats (`de-CH` for Switzerland), then the first one with a bare `<lang>` locale. Countries without
either use `en-001`. The chosen CLDR locale is written to `number_format_locale`.
"""
import json
import re
import sys
import urllib.request
from pathlib import Path

CLDR = "49.0.0"
BASE = f"https://raw.githubusercontent.com/unicode-org/cldr-json/{CLDR}/cldr-json"
KEYS = ["number_format_locale", "decimal_separator", "thousands_separator", "date_format", "currency_format"]
FALLBACK = "en-001"


def fetch(cache, path):
    target = cache / path.replace("/", "__")
    if not target.exists():
        with urllib.request.urlopen(f"{BASE}/{path}", timeout=60) as r:
            target.write_bytes(r.read())
    return json.loads(target.read_text(encoding="utf-8"))


BIDI_MARKS = re.compile("[\u200e\u200f\u061c]")


def numbers(cache, loc):
    data = fetch(cache, f"cldr-numbers-full/main/{loc}/numbers.json")["main"][loc]["numbers"]
    symbols = {k: BIDI_MARKS.sub("", v) for k, v in data["symbols-numberSystem-latn"].items() if k in ("decimal", "group")}
    return symbols, BIDI_MARKS.sub("", data["currencyFormats-numberSystem-latn"]["standard"])


def short_date(cache, loc):
    data = fetch(cache, f"cldr-dates-full/main/{loc}/ca-gregorian.json")["main"][loc]
    return BIDI_MARKS.sub("", data["dates"]["calendars"]["gregorian"]["dateFormats"]["short"])


def date_pattern(cldr):
    """CLDR short date pattern -> DD/MM/YYYY style tokens. Years always have four digits."""
    out, i = [], 0
    while i < len(cldr):
        c = cldr[i]
        if c == "'":
            end = cldr.index("'", i + 1)
            out.append(cldr[i + 1:end])
            i = end + 1
            continue
        run = len(re.match(re.escape(c) + "+", cldr[i:]).group())
        if c == "y":
            out.append("YYYY")
        elif c == "d" and run <= 2:
            out.append("D" * run)
        elif c in "ML" and run <= 2:
            out.append("M" * run)
        elif c == "G":
            pass  # era
        elif c.isalpha():
            raise ValueError(f"unsupported date pattern letter {c!r} in {cldr!r}")
        else:
            out.append(c * run)
        i += run
    return "".join(out).strip()


def currency_pattern(cldr):
    """CLDR currency pattern -> '{{amount}} {{symbol}}' style, positive part only."""
    positive = cldr.split(";")[0]
    result = re.sub(r"[#,0.]+", "{{amount}}", positive).replace("¤", "{{symbol}}")
    if result.count("{{amount}}") != 1 or result.count("{{symbol}}") != 1:
        raise ValueError(f"unsupported currency pattern {cldr!r}")
    return result


def pick_locale(cc, langs, available):
    for lang in langs:
        if f"{lang}-{cc}" in available:
            return f"{lang}-{cc}"
    for lang in langs:
        if lang in available:
            return lang
    return FALLBACK


def q(value):
    return json.dumps(value, ensure_ascii=True)


def main(cldr_dir, countries_dir, langs_file):
    cache = Path(cldr_dir)
    langs = json.loads(Path(langs_file).read_text())
    available = set(fetch(cache, "cldr-core/availableLocales.json")["availableLocales"]["full"])
    fallbacks = []
    for path in sorted(Path(countries_dir).glob("*.yaml")):
        cc = path.stem
        loc = pick_locale(cc, langs.get(cc) or [], available)
        if loc == FALLBACK:
            fallbacks.append(cc)
        symbols, currency = numbers(cache, loc)
        block = {
            "number_format_locale": loc,
            "decimal_separator": symbols["decimal"],
            "thousands_separator": symbols["group"],
            "date_format": date_pattern(short_date(cache, loc)),
            "currency_format": currency_pattern(currency),
        }
        lines = [l for l in path.read_text(encoding="utf-8").splitlines()
                 if not any(l.startswith(f"  {k}:") for k in KEYS)]
        lines += [f"  {k}: {q(v)}" for k, v in block.items()]
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"CLDR {CLDR}; fell back to {FALLBACK} for: {' '.join(fallbacks)}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
