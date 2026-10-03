#!/usr/bin/env python3
"""Regression check for CV generation with date-bearing YAML on Ruby 3.1+."""
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CVGenerationTest(unittest.TestCase):
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
