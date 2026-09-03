#!/usr/bin/env bash
# One-time provisioning: Netlify site link + GitHub app credentials + env vars.
# Default lane: GitHub App manifest flow (one browser click).
# Fallback lane: ./setup.sh --client-id <id> --client-secret-stdin  (paste secret, ^D)
set -euo pipefail
cd "$(dirname "$0")/.."

FORCE=0; CLIENT_ID=""; SECRET_STDIN=0
while [ $# -gt 0 ]; do case "$1" in
  --force) FORCE=1 ;;
  --client-id) CLIENT_ID="$2"; shift ;;
  --client-secret-stdin) SECRET_STDIN=1 ;;
  *) echo "unknown flag: $1" >&2; exit 1 ;;
esac; shift; done

if ! npx netlify status >/dev/null 2>&1; then
  echo "Netlify CLI not logged in — run: npx netlify login" >&2; exit 1
fi
if ! npx netlify status | grep -q "Project URL"; then
  npx netlify sites:create --name cs3540-lectures
  npx netlify link --name cs3540-lectures
fi
SITE_URL=$(npx netlify status | sed -n 's/.*Project URL:[^h]*\(https[^ ]*\).*/\1/p' | head -1)
echo "site: $SITE_URL"

if [ "$FORCE" = 0 ] && npx netlify env:list --plain --context production 2>/dev/null | grep -q '^GITHUB_CLIENT_ID='; then
  echo "env vars already present — re-run with --force to overwrite" >&2; exit 1
fi

if [ -n "$CLIENT_ID" ]; then
  [ "$SECRET_STDIN" = 1 ] || { echo "--client-id requires --client-secret-stdin" >&2; exit 1; }
  echo "paste the client secret, then Ctrl-D:"
  CLIENT_SECRET=$(cat)
else
  CREDS=$(npx tsx scripts/setup-app.ts "$SITE_URL")
  CLIENT_ID=$(echo "$CREDS" | sed -n 's/^CLIENT_ID=//p')
  CLIENT_SECRET=$(echo "$CREDS" | sed -n 's/^CLIENT_SECRET=//p')
fi
[ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ] || { echo "no credentials obtained" >&2; exit 1; }

CTX=(--context production --context deploy-preview --context branch-deploy)
npx netlify env:set GITHUB_CLIENT_ID "$CLIENT_ID"
npx netlify env:set GITHUB_CLIENT_SECRET "$CLIENT_SECRET" --secret "${CTX[@]}"
npx netlify env:set SESSION_SECRET "$(openssl rand -hex 32)" --secret "${CTX[@]}"
npx netlify env:set ADMIN_HANDLES "hunterino"
echo "done: GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, SESSION_SECRET, ADMIN_HANDLES set for $SITE_URL"
