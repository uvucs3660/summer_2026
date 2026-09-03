#!/usr/bin/env bash
# Publish the class lecture artifacts end-to-end: regenerate deck content
# with bin/build_lectures.dart, then build and deploy the lecture site
# (lecture_site/) to production Netlify.
#
# Usage: tool/publish_lectures.sh [build_lectures.dart flags...]
#   Flags (e.g. --slides-dir, --course, --year) pass through to the
#   generator; with none, it builds cs3540/2026. If you point the generator
#   at a non-default output dir, set CONTENT_DIR so the site build reads
#   the same place.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "==> Generating lecture decks (bin/build_lectures.dart $*)"
dart run bin/build_lectures.dart "$@"

cd lecture_site
echo "==> Deploying lecture site to production (https://cs3540-lectures.netlify.app)"
npm run deploy
