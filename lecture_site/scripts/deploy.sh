#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm run build
npx netlify deploy --prod --dir dist
