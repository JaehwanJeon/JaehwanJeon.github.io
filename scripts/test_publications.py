#!/usr/bin/env python3
"""Regression checks for papers.bib -> publications.yml -> CV (in-preparation section)."""
from pathlib import Path
import subprocess
import json
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

PREPARATION = [
    {
        "title": "An automated framework for substation topology extraction and ice and wind "
                 "fragility assessment using vision-language models",
        "category": "inpreparation",
        "venue": "In preparation",
        "citation": "Jeon, J., T. Kim*, J. E. Tate, and O. Kwon. An automated framework for substation "
                    "topology extraction and ice and wind fragility assessment using vision-language "
                    "models. (In preparation).",
    },
    {
        "title": "Modal-basis spatio-temporal Fourier neural operator for virtual sensing of structural "
                 "seismic responses",
        "category": "inpreparation",
        "venue": "In preparation",
        "citation": "Jeon, J., and J. Kim*. Modal-basis spatio-temporal Fourier neural operator for "
                    "virtual sensing of structural seismic responses. (In preparation).",
    },
]

LLM_TITLE = "Automating Structural Reliability Analysis with a Multi-Agent Large Language Model Framework"

# publications.yml order before the in-preparation section was added (same-date pairs included)
EXISTING_ORDER = [
    "joo2026operatorprior", "joo2026pet", "park2026iabsesindy", "park2026iabsepet", "guo2026rubber",
    "park2026ancrisst", "jeon2026llm", "joo2026isrerm", "park2026isrerm", "joo2026emi", "park2026emi",
    "joo2026kns", "jeon2026ensemble", "jeon2026dissertation", "jeon2026unified", "joo2025coseik",
    "jeon2025coseik", "joo2025cecar", "jeon2025cecar", "joo2025kepic", "joo2025icossar",
    "jeon2025icossar", "jeon2025emi", "jeon2025nnaugmented", "jeon2024ksce", "jeon2024apssra",
    "jeon2024wcee", "jeon2024eccomas", "jeon2024emipmc", "jeon2024smirt", "jeon2023ksce",
    "jeon2023icasp", "jeon2023emi", "jeon2022wcacem", "jeon2022coseik", "jeon2021kibse", "jeon2021ksce",
]


# keys bib2yaml.rb adds for the website only; the PDF CV ignores them
WEBSITE_ONLY = {"authors", "year", "details", "directions", "selected", "code"}


def cv_fields(entry):
    return {k: v for k, v in entry.items() if k not in WEBSITE_ONLY}


def load_yaml(path):
    result = subprocess.run([
        "ruby", "-ryaml", "-rdate", "-rjson", "-e",
        "puts JSON.generate(YAML.safe_load(File.read(ARGV[0]), permitted_classes: [Date]))",
        str(path)], check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def bib_keys():
    """(title, date) -> bib key; titles un-escaped the same way scripts/bib2yaml.rb does.
    Titles alone are not unique (the same paper was presented at several conferences)."""
    text = (ROOT / "_bibliography" / "papers.bib").read_text()
    keys = {}
    for match in re.finditer(r"@(\w+)\s*\{\s*([^,]+),(.*?)\n\}", text, re.S):
        title = re.search(r"^\s*title\s*=\s*\{(.*?)\}\s*,?\s*$", match[3], re.M)[1]
        date = re.search(r"^\s*date\s*=\s*\{(.*?)\}", match[3], re.M)
        title = re.sub(r"\s+", " ", title).replace("\\&", "&").replace("--", "–")
        keys[title, date and date[1]] = match[2].strip()
    return keys


def escaped(value):
    return re.sub(r"([&%$#_{}])", r"\\\1", value)


class PublicationDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pubs = load_yaml(ROOT / "_data" / "publications.yml")

    def test_committed_data_is_converter_output(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "publications.yml"
            subprocess.run(["ruby", str(ROOT / "scripts/bib2yaml.rb"), str(output)],
                           cwd=ROOT, check=True, capture_output=True)
            self.assertEqual(output.read_text(), (ROOT / "_data" / "publications.yml").read_text())

    def test_in_preparation_entries_are_exact_and_undated(self):
        self.assertEqual([cv_fields(p) for p in self.pubs if p["category"] == "inpreparation"], PREPARATION)
        self.assertEqual([cv_fields(p) for p in self.pubs[-len(PREPARATION):]], PREPARATION)

    def test_llm_has_choo_third_author(self):
        llm = [cv_fields(p) for p in self.pubs if p["title"] == LLM_TITLE]
        self.assertEqual(llm, [{
            "title": LLM_TITLE,
            "category": "underreview",
            "date": "2026-07-17",
            "venue": "Under review",
            "paperurl": "https://doi.org/10.48550/arXiv.2607.16580",
            "citation": f"Jeon, J., C. H. Lee, J. Choo, and T. Kim. {LLM_TITLE}. (Under review).",
        }])

    def test_website_fields(self):
        directions = {"physics", "uq", "automation"}
        for p in self.pubs:
            self.assertTrue(p.get("directions"), p["title"])
            self.assertLessEqual(set(p["directions"]), directions, p["title"])
            self.assertTrue(p.get("authors"), p["title"])
        selected = sorted((p for p in self.pubs if "selected" in p), key=lambda p: p["selected"])
        self.assertEqual([p["selected"] for p in selected], [1, 2, 3, 4])
        self.assertEqual(selected[-1]["title"], LLM_TITLE)

    def test_existing_entries_keep_their_order(self):
        keys = bib_keys()
        order = [keys[p["title"], p.get("date")] for p in self.pubs if p["category"] != "inpreparation"]
        self.assertEqual(order, EXISTING_ORDER)

    def test_website_section_follows_under_review(self):
        categories = list(load_yaml(ROOT / "_config.yml")["publication_category"])
        self.assertEqual(categories[categories.index("underreview") + 1], "inpreparation")
        self.assertEqual(categories[categories.index("inpreparation") + 1], "conferences")
        self.assertEqual(load_yaml(ROOT / "_config.yml")["publication_category"]["inpreparation"],
                         {"title": "Manuscripts in Preparation"})


class CVPreparationSectionTest(unittest.TestCase):
    def test_pdf_cv_lists_preparation_separately(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "cv.tex"
            subprocess.run(["ruby", str(ROOT / "scripts/build_cv_pdf.rb"), str(output)],
                           cwd=ROOT, check=True, capture_output=True)
            text = output.read_text()

        def subsection(name):
            return text.split(r"\subsection{" + name + "}", 1)[1].split("\\end{publist}", 1)[0]

        # since 524ce4a the CV splits journal work into published articles and manuscripts under review
        titles = re.findall(r"\\subsection\{([^}]+)\}", text)
        self.assertEqual(titles[titles.index("Published Journal Articles") + 1], "Manuscripts under Review")
        self.assertEqual(titles[titles.index("Manuscripts under Review") + 1], "Manuscripts in Preparation")
        self.assertEqual(titles[titles.index("Manuscripts in Preparation") + 1], "Conferences (International)")

        rows = re.findall(r"^(.+?) \\\\\[3pt\]$", subsection("Manuscripts in Preparation"), re.M)
        self.assertEqual(rows, [f"P{i}. & {escaped(p['citation'])}" for i, p in enumerate(PREPARATION, 1)])

        journals = subsection("Published Journal Articles")
        review = subsection("Manuscripts under Review")
        for p in PREPARATION:
            self.assertNotIn(escaped(p["title"]), journals)
            self.assertNotIn(escaped(p["title"]), review)
            self.assertEqual(text.count(escaped(p["title"])), 1)
        llm = escaped(f"Jeon, J., C. H. Lee, J. Choo, and T. Kim. {LLM_TITLE}. (Under review).")
        self.assertIn(llm, review)
        self.assertNotIn(llm, journals)


if __name__ == "__main__":
    unittest.main()
