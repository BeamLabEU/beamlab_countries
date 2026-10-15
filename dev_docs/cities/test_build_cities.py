"""Offline regressions for the GeoNames generator: python3 -I dev_docs/cities/test_build_cities.py."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location("build_cities", Path(__file__).with_name("build_cities.py"))
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class NameTests(unittest.TestCase):
    def test_preferred_short_name_beats_unpreferred_long_name(self):
        candidates = [(1, "Albuquerque", True, True), (2, "Methville", False, False)]
        self.assertEqual(generator.pick_name(candidates, locale="en"), "Albuquerque")

    def test_invalid_preferred_names_are_filtered(self):
        candidates = [(1, "Bad_Name", True, False), (2, "Лондон", True, False),
                      (3, "London", False, False)]
        self.assertEqual(generator.pick_name(candidates, locale="en"), "London")

    def test_locale_tag_fallback_skips_unusable_names(self):
        names = {"zh-CN": [(1, "London", True, False)], "zh": [(2, "伦敦", False, False)]}
        self.assertEqual(generator.translated_name(names, "zh", "London"), "伦敦")


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "source"
        self.output = self.root / "output"
        (self.source / "alt").mkdir(parents=True)
        metadata = {"langs": {"US": ["en"]}, "zones": {"US": ["America/New_York"]},
                    "us_ids": ["NY"]}
        for name, data in metadata.items():
            (self.source / f"{name}.json").write_text(json.dumps(data), encoding="utf-8")

        row = ["1", "Springfield", "Springfield", "", "40.0", "-74.0", "P", "PPLC",
               "US", "", "NY", "", "", "", "100000", "", "", "US/Eastern", "2026-01-01"]
        with zipfile.ZipFile(self.source / "cities1000.zip", "w") as archive:
            archive.writestr("cities1000.txt", "\t".join(row) + "\n")

    def test_generated_names_are_consistent_and_report_stays_in_output(self):
        rows = [["1", "1", "en", "Springfield", "1", "1", "", ""],
                ["2", "1", "en", "Unpreferred alternative", "", "", "", ""],
                ["3", "1", "zh-CN", "Wrong script", "1", "", "", ""],
                ["4", "1", "zh", "斯普林菲尔德", "", "", "", ""]]
        with zipfile.ZipFile(self.source / "alt" / "US.zip", "w") as archive:
            archive.writestr("US.txt", "\n".join("\t".join(row) for row in rows))

        with contextlib.redirect_stdout(io.StringIO()):
            generator.build(self.source, self.output)

        [city] = json.loads((self.output / "US.json").read_text(encoding="utf-8"))
        self.assertEqual(city["name"], "Springfield")
        self.assertEqual(city["native_name"], "Springfield")
        self.assertNotIn("en", city["translations"])
        self.assertEqual(city["translations"]["zh"], "斯普林菲尔德")
        self.assertEqual(city["timezone"], "America/New_York")
        self.assertTrue(city["capital"])
        self.assertTrue((self.output / "report.txt").exists())
        self.assertFalse((self.root / "report.txt").exists())

    def test_missing_alternate_names_fail_before_writing_output(self):
        with self.assertRaisesRegex(FileNotFoundError, "Missing alternate-name archives: US"):
            generator.build(self.source, self.output)
        self.assertFalse(self.output.exists())

    def canadian_source(self):
        (self.source / "langs.json").write_text(json.dumps({"CA": ["en", "fr"]}), encoding="utf-8")
        (self.source / "zones.json").write_text(json.dumps({"CA": ["America/Toronto"]}), encoding="utf-8")
        rows = []
        expected = {}
        for index, (admin1, province) in enumerate(generator.CA.items()):
            expected[province] = []
            for rank in range(12):
                gid = 1000 + index * 100 + rank
                row = [str(gid), f"{province} Place {rank:02d}", "", "", "45.0", "-75.0", "P",
                       "PPLL" if province in {"NU", "NT", "YT"} else "PPL", "CA", "", admin1,
                       "", "", "", str(5000 - rank * 450), "", "", "America/Toronto", "2026-01-01"]
                rows.append(row)
                if rank < 10:
                    expected[province].append(gid)

        with zipfile.ZipFile(self.source / "cities1000.zip", "w") as archive:
            archive.writestr("cities1000.txt", "\n".join("\t".join(r) for r in rows
                                                       if int(r[14]) >= 1000 and r[7] != "PPLL"))
        with zipfile.ZipFile(self.source / "CA.zip", "w") as archive:
            archive.writestr("CA.txt", "\n".join("\t".join(r) for r in rows))
        with zipfile.ZipFile(self.source / "alt" / "CA.zip", "w") as archive:
            archive.writestr("CA.txt", "")
        return expected

    def test_canadian_subdivisions_include_ten_places_from_both_sources_without_duplicate_ids(self):
        expected = self.canadian_source()
        with contextlib.redirect_stdout(io.StringIO()):
            generator.build(self.source, self.output)

        cities = json.loads((self.output / "CA.json").read_text(encoding="utf-8"))
        self.assertEqual(len(cities), 130)
        self.assertEqual(len({c["id"] for c in cities}), 130)
        for province, ids in expected.items():
            self.assertEqual([c["id"] for c in cities if c["subdivision"] == province], ids)

    def test_insufficient_canadian_subdivision_coverage_fails(self):
        self.canadian_source()
        with zipfile.ZipFile(self.source / "CA.zip", "w") as archive:
            archive.writestr("CA.txt", "")

        with contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(ValueError, "Canada needs at least 10 populated places"):
                generator.build(self.source, self.output)

    def test_us_state_selection_includes_ten_cities(self):
        rows = [[str(1000 + rank), f"Place {rank:02d}", "", "", "40.0", "-74.0", "P", "PPL",
                 "US", "", "NY", "", "", "", str(20000 - rank * 1000), "", "", "America/New_York",
                 "2026-01-01"] for rank in range(12)]
        with zipfile.ZipFile(self.source / "cities1000.zip", "w") as archive:
            archive.writestr("cities1000.txt", "\n".join("\t".join(r) for r in rows))
        with zipfile.ZipFile(self.source / "alt" / "US.zip", "w") as archive:
            archive.writestr("US.txt", "")

        with contextlib.redirect_stdout(io.StringIO()):
            generator.build(self.source, self.output)

        cities = json.loads((self.output / "US.json").read_text(encoding="utf-8"))
        self.assertEqual([c["id"] for c in cities], list(range(1000, 1010)))

    def test_us_non_states_are_not_padded_with_neighbourhoods(self):
        (self.source / "us_ids.json").write_text(json.dumps(["NY", "DC"]), encoding="utf-8")
        rows = []
        for rank in range(12):
            # Spread places so the 12 km collapse does not empty the national top 10.
            lat = f"{40.0 + rank:g}"
            rows.append([str(1000 + rank), f"NY {rank:02d}", "", "", lat, "-74.0", "P", "PPL",
                         "US", "", "NY", "", "", "", str(20000 - rank * 1000), "", "",
                         "America/New_York", "2026-01-01"])
            rows.append([str(2000 + rank), f"DC {rank:02d}", "", "", lat, "-77.0", "P", "PPL",
                         "US", "", "DC", "", "", "", str(500 - rank), "", "",
                         "America/New_York", "2026-01-01"])
        with zipfile.ZipFile(self.source / "cities1000.zip", "w") as archive:
            archive.writestr("cities1000.txt", "\n".join("\t".join(r) for r in rows))
        with zipfile.ZipFile(self.source / "alt" / "US.zip", "w") as archive:
            archive.writestr("US.txt", "")

        with contextlib.redirect_stdout(io.StringIO()):
            generator.build(self.source, self.output)

        cities = json.loads((self.output / "US.json").read_text(encoding="utf-8"))
        self.assertEqual([c["id"] for c in cities], list(range(1000, 1010)))
        self.assertTrue(all(c["subdivision"] == "NY" for c in cities))


if __name__ == "__main__":
    unittest.main()
