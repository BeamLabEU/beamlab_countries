"""Offline regressions: python3 -I dev_docs/formats/test_build_formats.py."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("build_formats", Path(__file__).with_name("build_formats.py"))
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class PatternTests(unittest.TestCase):
    def test_dates_keep_padding_literals_and_four_digit_years(self):
        for source, expected in [("M/d/yy", "M/D/YYYY"), ("dd.MM.y", "DD.MM.YYYY"),
                                 ("d.MM.y\u202f'г'.", "D.MM.YYYY\u202fг."),
                                 ("d 'de' M 'de' y G", "D de M de YYYY")]:
            with self.subTest(source=source):
                self.assertEqual(generator.date_pattern(source), expected)

    def test_escaped_apostrophes_are_not_discarded(self):
        self.assertEqual(generator.date_pattern("dd/MM/y 'o''clock'"), "DD/MM/YYYY o'clock")
        self.assertEqual(generator.date_pattern("dd/MM/y ''"), "DD/MM/YYYY '")

    def test_invalid_date_patterns_fail(self):
        for source in ["MMM d, y", "YYYY-MM-dd", "dd/MM/y 'broken"]:
            with self.subTest(source=source), self.assertRaises(ValueError):
                generator.date_pattern(source)

    def test_currency_pattern_keeps_spacing_and_only_the_positive_form(self):
        self.assertEqual(generator.currency_pattern("#,##0.00\u00a0¤;(#,##0.00\u00a0¤)"),
                         "{{amount}}\u00a0{{symbol}}")
        self.assertEqual(generator.currency_pattern("¤#,##0.00"), "{{symbol}}{{amount}}")

    def test_unsupported_currency_patterns_fail(self):
        for source in ["#,##0.00", "¤¤ #,##0.00", "¤0E0"]:
            with self.subTest(source=source), self.assertRaises(ValueError):
                generator.currency_pattern(source)


class LocaleTests(unittest.TestCase):
    def test_regional_locales_take_priority_over_bare_languages(self):
        self.assertEqual(generator.pick_locale("CH", ["de", "fr"], {"de", "fr-CH"}), "fr-CH")

    def test_language_order_breaks_ties(self):
        self.assertEqual(generator.pick_locale("CH", ["de", "fr"], {"de-CH", "fr-CH"}), "de-CH")
        self.assertEqual(generator.pick_locale("DE", ["de", "en"], {"de", "en"}), "de")

    def test_unknown_languages_use_the_world_english_fallback(self):
        for languages in [[], ["xx"]]:
            self.assertEqual(generator.pick_locale("AQ", languages, {"en-001"}), "en-001")


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.cache = self.root / "new" / "cache"
        self.countries = self.root / "countries"
        self.countries.mkdir()
        self.langs = self.root / "langs.json"
        self.langs.write_text(json.dumps({"DE": ["de"]}), encoding="utf-8")
        self.country = self.countries / "DE.yaml"
        self.country.write_text('DE:\n  name: Germany\n  decimal_separator: "old"\n', encoding="utf-8")

    def fetch(self, cache, path):
        self.assertTrue(cache.is_dir())
        if path == "cldr-core/availableLocales.json":
            return {"availableLocales": {"full": ["de", "en-001"]}}
        locale = path.split("/")[2]
        if path.endswith("numbers.json"):
            return {"main": {locale: {"numbers": {
                "symbols-numberSystem-latn": {"decimal": ",", "group": "."},
                "currencyFormats-numberSystem-latn": {"standard": "\u200f#,##0.00\u00a0¤"},
            }}}}
        return {"main": {locale: {"dates": {"calendars": {"gregorian": {
            "dateFormats": {"short": "dd.MM.yy"},
        }}}}}}

    def run_generator(self):
        with contextlib.redirect_stdout(io.StringIO()):
            generator.main(self.cache, self.countries, self.langs)

    def test_new_cache_regeneration_and_repeat_runs(self):
        with patch.object(generator, "fetch", side_effect=self.fetch):
            self.run_generator()
            content = self.country.read_text(encoding="utf-8")
            self.assertIn('  name: Germany\n', content)
            self.assertIn('  number_format_locale: "de"\n', content)
            self.assertIn('  decimal_separator: ","\n', content)
            self.assertIn('  date_format: "DD.MM.YYYY"\n', content)
            self.assertIn('  currency_format: "{{amount}}\\u00a0{{symbol}}"\n', content)
            self.assertEqual(content.count("  decimal_separator:"), 1)
            self.run_generator()
            self.assertEqual(self.country.read_text(encoding="utf-8"), content)

    def test_source_errors_leave_all_country_files_unchanged(self):
        second = self.countries / "XX.yaml"
        second.write_text("XX:\n  name: Unknown\n", encoding="utf-8")
        original = {p: p.read_bytes() for p in [self.country, second]}

        def fetch(cache, path):
            if "/en-001/" in path:
                raise OSError("source unavailable")
            return self.fetch(cache, path)

        with patch.object(generator, "fetch", side_effect=fetch):
            with self.assertRaisesRegex(OSError, "source unavailable"):
                self.run_generator()
        self.assertEqual({p: p.read_bytes() for p in original}, original)

    def test_fetch_downloads_once_and_reuses_cache(self):
        self.cache.mkdir(parents=True)
        response = io.BytesIO(b'{"value": "cached"}')
        with patch.object(generator.urllib.request, "urlopen", return_value=response) as request:
            self.assertEqual(generator.fetch(self.cache, "example/data.json"), {"value": "cached"})
            self.assertEqual(generator.fetch(self.cache, "example/data.json"), {"value": "cached"})
            request.assert_called_once()


if __name__ == "__main__":
    unittest.main()
