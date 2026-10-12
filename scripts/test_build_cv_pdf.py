#!/usr/bin/env python3
"""Regression check for CV generation with date-bearing YAML on Ruby 3.1+."""
from pathlib import Path
import subprocess
import json
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CVGenerationTest(unittest.TestCase):
    def test_requested_sections_are_newest_first(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "cv.tex"
            subprocess.run(["ruby", str(ROOT / "scripts/build_cv_pdf.rb"), str(output)],
                           cwd=ROOT, check=True, capture_output=True)
            text = output.read_text()

        def section(name):
            return text.split(r"\section{" + name + "}", 1)[1].split(r"\section{", 1)[0]

        experience = section("Professional Experience")
        labels = re.findall(r"^([^&\n]+) &", experience, re.M)
        months = {name: i for i, name in enumerate(
            ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"], 1)}
        def date_key(label):
            match = re.search(r"\d{4}", label)
            assert match is not None, label
            year = int(match[0])
            numeric = re.search(r"\d{4}\.(\d{2})", label)
            month = int(numeric[1]) if numeric else next(
                (v for k, v in months.items() if k in label.lower()),
                9 if "Fall" in label else 3 if "Spring" in label else 1)
            return year, month
        with self.subTest(section="D"):
            dates = [date_key(label) for label in labels]
            self.assertEqual(dates, sorted(dates, reverse=True))

        def data(name):
            result = subprocess.run([
                "ruby", "-ryaml", "-rdate", "-rjson", "-e",
                "puts JSON.generate(YAML.safe_load(File.read(ARGV[0]), permitted_classes: [Date]))",
                str(ROOT / "_data" / name)], check=True, capture_output=True, text=True)
            return json.loads(result.stdout)

        def escaped(value):
            return re.sub(r"([&%$#_{}])", r"\\\1", value)

        pubs = data("publications.yml")
        groups = {
            "F2": sorted([p for p in pubs if p["category"] == "manuscripts"],
                         key=lambda p: p["date"], reverse=True)
                  + sorted([p for p in pubs if p["category"] == "underreview"],
                           key=lambda p: p["date"], reverse=True),
            "F3": sorted([p for p in pubs if p["category"] == "conferences" and p.get("scope") == "international"],
                         key=lambda p: p["date"], reverse=True),
            "F4": sorted([p for p in pubs if p["category"] == "conferences" and p.get("scope") == "domestic"],
                         key=lambda p: p["date"], reverse=True),
        }
        for name, entries in groups.items():
            with self.subTest(section=name):
                positions = [text.index(escaped(p["citation"])) for p in entries]
                self.assertEqual(positions, sorted(positions))
        with self.subTest(section="I"):
            talks = sorted(data("talks.yml"), key=lambda t: t["date"], reverse=True)
            positions = [section("Invited Talks and Seminars").index(escaped(t["title"])) for t in talks]
            self.assertEqual(positions, sorted(positions))

    def test_generator_loads_yaml_dates(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "cv.tex"
            result = subprocess.run(
                ["ruby", str(ROOT / "scripts/build_cv_pdf.rb"), str(output)],
                cwd=ROOT, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            text = output.read_text()
            self.assertIn(r"\begin{document}", text)
            self.assertIn(r"\end{document}", text)
            self.assertIn("Invited Guest Lecturer", text)
            self.assertIn("Research Innovation Technology Seminar", text)
            self.assertIn("September 30, 2026", text)
            self.assertIn("October 1, 2026", text)


if __name__ == "__main__":
    unittest.main()
