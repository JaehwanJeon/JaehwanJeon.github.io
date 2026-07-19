#!/usr/bin/env bash
# One-click PDF CV build: homepage data -> LaTeX -> files/CV.pdf
# Requires: host ruby (stdlib only) + MacTeX (latexmk/pdflatex).
# Note: run scripts/bib2yaml.rb (in the dev container) first if papers.bib changed.
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD=.cv_build
mkdir -p "$BUILD"

ruby scripts/build_cv_pdf.rb "$BUILD/cv.tex"

PHOTO=$(ruby -ryaml -e 'puts YAML.load_file("_data/cv_extra.yml").dig("personal","photo").to_s')
if [[ -n "$PHOTO" && -f "$PHOTO" ]]; then
  cp "$PHOTO" "$BUILD/photo.jpg"
fi

latexmk -pdf -halt-on-error -interaction=nonstopmode -output-directory="$BUILD" "$BUILD/cv.tex" >"$BUILD/latexmk.log" 2>&1 || {
  echo "LaTeX build failed — see $BUILD/latexmk.log" >&2
  tail -30 "$BUILD/latexmk.log" >&2
  exit 1
}

cp "$BUILD/cv.pdf" files/CV.pdf
echo "OK: files/CV.pdf updated ($(du -h files/CV.pdf | cut -f1 | tr -d ' '))"
