#!/usr/bin/env bash
# SPEC.md section 9 verification for a cheatsheets directory.
# Usage: scripts/check_cheatsheets.sh <cheatsheets-dir>
set -uo pipefail

dir="${1:?usage: check_cheatsheets.sh <cheatsheets-dir>}"
cd "$dir"
fail=0

for md in *.md; do
  [ "$md" = "SPEC.md" ] || [ "$md" = "CATALOG.md" ] && continue
  grep -oE 'diagrams/[a-z0-9-]+\.svg' "$md" | sort -u | while read -r ref; do
    [ -f "$ref" ] || { echo "MISSING REF  $md -> $ref"; exit 1; }
  done || fail=1
done

for f in diagrams/*.svg; do
  xmllint --noout "$f" 2>/dev/null || { echo "MALFORMED    $f"; fail=1; }
  # SPEC: viewBox only on the <svg> root; never width/height there.
  root="$(head -1 "$f")"
  case "$root" in
    *"<svg"*) ;;
    *) echo "NO SVG ROOT ON LINE 1  $f"; fail=1; continue ;;
  esac
  case "$root" in *viewBox=*) ;; *) echo "NO VIEWBOX   $f"; fail=1 ;; esac
  case "$root" in *" width="*|*" height="*) echo "ROOT W/H     $f"; fail=1 ;; esac
done

for f in diagrams/*.svg; do
  name="$(basename "$f")"
  grep -lqE "diagrams/$name" ./*.md 2>/dev/null || { echo "ORPHAN       $f"; fail=1; }
done

for md in *.md; do
  [ "$md" = "SPEC.md" ] || [ "$md" = "CATALOG.md" ] && continue
  grep -q '^## Common gotchas' "$md"   || { echo "NO GOTCHAS   $md"; fail=1; }
  grep -q "^## When you're stuck" "$md" || { echo "NO STUCK     $md"; fail=1; }
  grep -qE '^!\[' "$md"                || { echo "NO DIAGRAM   $md"; fail=1; }
  head -1 "$md" | grep -qE '^# .+Cheat Sheet \(80/20\)$' || { echo "BAD TITLE    $md"; fail=1; }
done

count=$(ls -1 *.md 2>/dev/null | grep -vcE '^(SPEC|CATALOG)\.md$')
if [ "$fail" -eq 0 ]; then
  echo "CLEAN — $count cheat sheets, $(ls -1 diagrams/*.svg 2>/dev/null | wc -l | tr -d ' ') diagrams"
else
  echo "FAILED"; exit 1
fi
