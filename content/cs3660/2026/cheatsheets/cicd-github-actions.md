# CI/CD with GitHub Actions Cheat Sheet (80/20)

The 20% of CI/CD you'll need to ship a Sprint 3 capstone with a real working pipeline. The Perfect Framework's *CI/CD* concern says: every commit goes through automated checks; every merge produces a versioned, deployable artifact; deploys are one-button. This sheet gets you to that bar with GitHub Actions.

This is opinionated toward GitHub Actions because Sprint repos already live on GitHub. The principles transfer to GitLab CI, CircleCI, Jenkins — only the YAML syntax differs.

## The shape of a useful pipeline

```
[ commit / push ] → [ test job ] ─────────────────→ [ build job ] → [ deploy job ]
                          ↓                                              ↓
                  [ PR check status ]                              [ production env ]
```

Three stages, each independently meaningful:

- **Test** — runs on every push and PR. Fails the PR if anything breaks.
- **Build** — produces a versioned artifact (Docker image, zip, etc.).
- **Deploy** — pushes the artifact to staging/production. Triggered on merge to main (continuous deployment) or by tag (release-based).

## Minimum-viable workflow

A working `.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
```

This is enough to satisfy "tests run on PR." Sprint 3 rubric: required.

## Adding a deploy job

```yaml
  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: |
          npm ci
          npm run build

      - name: Deploy to Netlify
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID:    ${{ secrets.NETLIFY_SITE_ID }}
        run: npx netlify-cli deploy --prod --dir=dist
```

`needs: test` ensures tests pass before deploy runs. `if: github.ref == 'refs/heads/main'` only deploys on merge to main, not on PRs.

## Secrets and environment

Never commit secrets. GitHub Actions reads them from `${{ secrets.NAME }}`:

- **Repo settings → Secrets and variables → Actions → New secret.**
- Name patterns: `NETLIFY_AUTH_TOKEN`, `AWS_ACCESS_KEY_ID`, `DATABASE_URL`.
- Org-level secrets cascade to repos in the org.
- Environment-scoped secrets (`environments/production/secrets`) are a step further — protected with manual approval gates.

## Caching for speed

A cold install of `npm ci` takes 30-60 seconds. With caching, it's 5 seconds.

```yaml
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'              # or 'yarn', 'pnpm'
```

The action handles the cache key (lockfile hash). For Dart, Python, Rust — equivalent caching actions exist.

For Docker layer caching:

```yaml
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v5
        with:
          context: .
          cache-from: type=gha
          cache-to:   type=gha,mode=max
```

GitHub-hosted cache for Docker layers. Big speedup on subsequent builds.

## Matrix builds

Test against multiple versions:

```yaml
  test:
    strategy:
      matrix:
        node-version: ['20', '22']
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      # ...
```

A 2×2 matrix runs 4 parallel jobs. Catch version-specific bugs before they ship.

## Deploy strategies

Three patterns, in increasing complexity:

### Rolling deploy

Replace instances one at a time. Default for most platforms.

```yaml
      - name: Deploy
        run: |
          # K8s rolling update:
          kubectl set image deployment/api api=ghcr.io/.../api:${{ github.sha }}
          kubectl rollout status deployment/api
```

The platform handles "old version still serving while new spins up."

### Blue-green

Run BOTH the old and new versions simultaneously. Flip traffic atomically.

```yaml
      - name: Deploy green
        run: kubectl apply -f deployments/green.yaml

      - name: Wait for green to be healthy
        run: |
          kubectl rollout status deployment/green
          curl -fsS https://green.example.com/health

      - name: Switch traffic
        run: kubectl patch service api -p '{"spec":{"selector":{"color":"green"}}}'
```

**Pros**: instant rollback (point service back at blue). **Cons**: 2× resource cost during deploys.

### Canary

Route a small fraction of traffic to new; widen if metrics look good.

```yaml
      - name: Deploy canary (10%)
        run: kubectl apply -f canary-10.yaml

      - name: Wait, then check canary metrics
        run: |
          sleep 300  # 5 min observation
          ./scripts/check-canary-metrics.sh

      - name: Promote to 100%
        run: kubectl apply -f canary-100.yaml
```

**Pros**: catches regressions before they affect everyone. **Cons**: requires good metrics + clear pass/fail criteria.

For Sprint 3 capstones: rolling is fine. Blue-green is impressive in a demo if you have spare resources. Canary is real-world but rarely needed at student-project scale.

## Required vs. optional checks

Branch protection rules let you require certain jobs to pass before merging:

- **Required**: typecheck, lint, unit tests. Block the merge button if these fail.
- **Optional**: integration tests (sometimes flaky), performance benchmarks, end-to-end suites (slow). Run on schedule or on-demand instead of on every PR.

Set up: Repo settings → Branches → Branch protection rules → main → Require status checks.

## Versioned artifacts

Every build produces a deployable artifact tagged with something stable. The git SHA is the easy answer:

```yaml
      - name: Build and push image
        run: |
          docker build -t ghcr.io/owner/repo:${{ github.sha }} .
          docker push ghcr.io/owner/repo:${{ github.sha }}
```

Then `kubectl set image ... :${{ github.sha }}` to deploy. To roll back: deploy a previous SHA.

For releases, tag-based versions:

```yaml
on:
  push:
    tags: ['v*']

jobs:
  release:
    # tagged: v1.0.0 → image: ghcr.io/owner/repo:v1.0.0
```

## One-button rollback

The Perfect Framework concern says: rollback should be one click.

Three paths:

1. **Re-run a previous deploy workflow** — GitHub Actions UI: pick a past successful run, "Re-run jobs."
2. **Manual workflow** — a `workflow_dispatch` workflow that takes a SHA/tag input and deploys it:

```yaml
on:
  workflow_dispatch:
    inputs:
      sha:
        description: 'Git SHA to deploy'
        required: true

jobs:
  deploy:
    # ... uses ${{ github.event.inputs.sha }}
```

3. **Platform native rollback** — `kubectl rollout undo deployment/api` reverts to the previous version.

## Observability inside CI

When CI fails, you want to know why fast:

- **Test output** — make sure failed tests print enough context (line numbers, expected vs. actual).
- **Annotations** — GitHub Actions parses common formats (TAP, JUnit XML) and shows annotations inline on the PR diff.
- **Artifact uploads** — failed test screenshots, log files, build outputs:

```yaml
      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test-results/
```

## Common failure modes

- **Tests pass locally, fail in CI.** Almost always: environment difference. Pin Node version explicitly; declare DB schema explicitly; freeze dates in tests.
- **Secret leaked in logs.** GitHub Actions auto-redacts known secrets, but env vars echoed by your script may slip through. Don't `echo $TOKEN`.
- **Long-running jobs.** Default timeout is 6h; that's not a feature. Set `timeout-minutes: 15` on jobs to fail fast.
- **Manual steps in deploy.** "We deploy by ssh'ing in and running migrate." That's not a deploy; that's a runbook. Automate it.
- **No staging environment.** Production is your test environment. Add staging — a separate domain, separate DB, redeployed on every main merge.

## What this is in vernacular

- The pipeline IS the Perfect Framework's *CI/CD* concern operationalized.
- Versioned artifacts ≈ **Document Message** (EIP) at the deploy boundary — each artifact is a versioned, immutable payload.
- Blue-green deploy ≈ **Strategy** (GoF) applied to traffic routing — switch the strategy atomically.
- Canary deploy ≈ **Scatter-Gather** (EIP) reading metrics from N% of traffic before the global decision.

## Further reading

- **GitHub Actions docs** — `docs.github.com/en/actions`. The reference and a friendly tutorial.
- **GitHub Actions workflow syntax** for the YAML reference.
- **`cheatsheet-observability-logs-metrics-traces`** — the metrics canary deploys read.
- **The Twelve-Factor App** (12factor.net) — the production-readiness checklist that aged well.
- **Google SRE book** — broader CI/CD philosophy.
