#!/usr/bin/env bash
# Render every handout HTML in this directory to a print-ready Letter PDF.
#
# Chrome headless is used rather than LibreOffice: LibreOffice's Writer/Web
# import silently drops table borders and column widths, which is exactly the
# part of a signup sheet that has to survive.
set -euo pipefail

cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[[ -x "$CHROME" ]] || { echo "error: Chrome not found at $CHROME" >&2; exit 1; }

for html in *.html; do
  pdf="${html%.html}.pdf"
  "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$PWD/$pdf" "file://$PWD/$html" 2>/dev/null
  pages=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages/{print $2}')
  echo "  $pdf (${pages:-?} page(s))"
done
