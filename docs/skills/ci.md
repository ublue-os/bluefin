# Bluefin CI/CD Skill

Diagnose and fix GitHub Actions failures in Bluefin repos.

## When to Use

- A GitHub Actions workflow is failing in any Bluefin repo
- Understanding the CI pipeline structure or job dependencies
- Checking build status on a branch or PR
- Diagnosing common build failures (OOM, rate limits, signing, pre-commit)

## When NOT to Use

- Local build failures unrelated to CI — use [docs/skills/build.md](docs/skills/build.md)
- Package-level changes that need testing — use [docs/skills/packages.md](docs/skills/packages.md)
- ISO-specific pipeline failures — use [docs/skills/iso.md](docs/skills/iso.md)

## How It Works

1. Check current CI status: `bash /mnt/skills/user/bluefin-ci/scripts/check-ci.sh`
2. Identify failing job and read logs
3. Apply fix and re-run

## Usage

```bash
# Check CI on current branch

# Read full logs for failed run
gh run view RUN_ID --log-failed
```

## Output

check-ci.sh prints current run status and highlights failures.

## Common CI Failures

| Failure | Cause | Fix |
|---|---|---|
| `just check` fails | Justfile formatting | `just fix` |
| pre-commit fails | Lint/format issue | `pre-commit run --all-files` and fix |
| Build OOM | Not enough memory in runner | Reduce parallelism in workflow |
| Container pull rate limit | ghcr.io rate limit | Wait and re-run |
| COPR package not found | COPR repo down or package removed | Check COPR repo status |
| Cosign verification fails | Image not signed | Check signing step in workflow |

## Workflow Files

Key CI workflows in `.github/workflows/`:
- `build.yml` — main build pipeline
- `build-iso.yml` — ISO builds (in bluefin-iso repo)
- `promote-iso.yml` — ISO promotion
- `pr.yml` — PR validation

> Never use `web_fetch` for GitHub URLs. See: github skill for the full rule.

## Re-running Failed Jobs

```bash
gh run rerun RUN_ID --failed-only
```

## Learnings

### Copilot PR review caught real bug in create-lts-pr.yml (added 2026-03-17)

Copilot reviewed PR #1195 and left 4 comments. All were valid. Key findings:

**What:** `git log origin/lts..origin/main --oneline` in the "Build commit list" step bloats after squash-merge promotions. Confirmed recurring in production.

**Why:** Squash-merge loses individual commit provenance. `lts` gets one commit, so the range walks back to the original divergence point and lists all historical commits.

**Fix:** Tree-hash anchor (see bluefin-lts skill → "NEVER use git log origin/lts..origin/main"). Fixed in PR #1197.

**|| true silences failures — don't use on body-update steps:**
`gh pr edit ... || true` masked API failures, leaving the promotion PR body stale with no signal. Removed in PR #1197. Maintainers rely on the PR body to know what's being promoted — silent stale body = risk of wrong merge.

**Don't repeat:** Never use `|| true` on `gh pr edit` or any step where failure would leave a human-visible artifact in a stale/wrong state.

### Workflow files in bluefin-lts (added 2026-03-17)

The bluefin-ci skill listed old/wrong workflow names. Correct list for bluefin-lts:
- `build-regular.yml`, `build-dx.yml`, `build-gdx.yml`, `build-regular-hwe.yml`, `build-dx-hwe.yml` — callers
- `reusable-build-image.yml` — reusable workflow all callers invoke
- `scheduled-lts-release.yml` — weekly Tuesday 6am UTC production release dispatcher
- `create-lts-pr.yml` — auto-creates/updates draft promotion PR (main→lts)
- `generate-release.yml` — creates GitHub Release after GDX build on lts

<!-- Background agents append here automatically -->

### generate-release fails: No SBOM referrer found (added 2026-05-28)

**What:** `generate-release.yml` fails at "Generate Release Text" with:
```
RuntimeError: No SBOM referrer found for ghcr.io/ublue-os/<image>@sha256:...
```

**Why:** `changelogs.py` fetches SBOMs for both the current and previous stable tags to build a package diff. Tags built before SBOM attachment was added to the pipeline have no SBOM referrer, causing a hard failure.

**Fix pattern applied (PR #4677):**
1. Add `allow_missing_sbom=True` to `get_packages()` — only suppresses "No SBOM referrer found" RuntimeError; all other errors still propagate
2. Pass `allow_missing_sbom=True` for both current and previous tag fetches
3. Use intersection of images (both sides have SBOM data) for the diff — avoids false "all packages added" output
4. Add `re.sub(r"\{pkgrel:[^}]+\}", "N/A", changelog)` to clean up unresolved version placeholders

**How to manually retrigger the stable release:**
```bash
gh workflow run generate-release.yml \
  --repo ublue-os/bluefin \
  --ref <branch-with-fix> \
  --field stream_name='["stable"]'
```
Watch: `gh run watch <RUN_ID> --repo ublue-os/bluefin`

**Note:** The `generate-release.yml` workflow creates a real GitHub release when triggered via `workflow_dispatch` for the "stable" stream. Confirm the release was created with `gh release list --repo ublue-os/bluefin`.

### dakota publish pipeline — e2e gates :latest (added 2026-05-30)

**Pattern:** `publish.yml` is a 4-stage pipeline: `setup → publish → e2e-gate → promote`

- `publish`: exports from CAS, pushes `:$sha`, signs, SBOM, attests — fires on all triggers
- `e2e-gate`: smoke-tests `ghcr.io/projectbluefin/dakota:$sha` via `projectbluefin/testsuite` — schedule/dispatch only
- `promote`: re-tags `:$sha` → `:latest` after e2e passes — schedule/dispatch only

`:latest` is never published without a passing e2e smoke test.

**e2e path filter behavior:** `e2e.yml` has `paths:` filter on `elements/`, `files/`, `patches/`, `Justfile`, `project.conf`. When a PR doesn't touch those paths, GitHub marks e2e as **skipped** — skipped counts as passing for the required status check. This is intentional: action pin bumps skip e2e; junction bumps in `elements/` run e2e.

**Ruleset (dakota):** Required status checks: `validate` + `e2e`. Bypass actors: OrganizationAdmin, Renovate (2740), mergeraptor (3069633).

**Key bypass actor IDs:**
- Renovate: integration ID `2740`
- mergeraptor: integration ID `3069633`

### projectbluefin/bluefin e2e — GNOME 50 AT-SPI changes (added 2026-05-31)

**Context:** `projectbluefin/bluefin` e2e smoke suite runs against headless GNOME 50 in QEMU via `projectbluefin/testsuite`. GNOME 50 introduced several AT-SPI and UI structural changes that break tests written for GNOME 47–48.

**Key GNOME 50 AT-SPI changes to know:**

| Widget | Old (≤48) | New (50) |
|---|---|---|
| Nautilus app name | `"nautilus"` | `"Files"` or `"org.gnome.Nautilus"` |
| Nautilus sidebar — Home | `roleName: list item`, name `"Home"` | `roleName: button`, name `"Home Home"` |
| Nautilus sidebar — bookmarks | `roleName: list item`, short name | `roleName: list item`, full path (e.g. `/var/home/user/Downloads`) |
| Nautilus breadcrumb | `roleName: toggle button`, name `"Downloads"` | `roleName: label`, full path string |
| Nautilus new-folder | Traditional dialog with AT-SPI text entry | Inline popover — AT-SPI entry may not be exposed in headless QEMU |
| Nautilus search bar | AT-SPI text entry visible after Ctrl+F | May not surface in headless QEMU |
| Extensions process | `pgrep -f gnome-extensions` finds it | Process name varies; pgrep unreliable |
| GNOME Shell DND | `_do_not_disturb.checked` via Shell.Eval | `_do_not_disturb` is `undefined`; use gsettings fallback |
| Notification banner | `banner.destroy()` dismisses | `banner.destroy()` has no effect in headless QEMU — make soft warn |

**Fix patterns:**

1. **Nautilus app lookup**: try multiple names in order: `"Files"`, `"org.gnome.Nautilus"`, `"nautilus"`, `"gnome-files"`. Patch `dtree.root.application` at instance level in `environment.py`.

2. **Sidebar navigation**: use `"button"` for Home, `"list item"` for bookmarks (substring match on short name still works with full-path widget name).

3. **Breadcrumb location check**: add a custom step `Nautilus location shows "{location}"` that calls `app.findChildren(lambda n: n.showing and location.lower() in (n.name or "").lower())`.

4. **New-folder/search-bar AT-SPI**: search broadly for any `text`/`entry` widget; demote to `WARNING + return` if not found (not hard failure) — coredump scenario covers crashes.

5. **Extensions soft-pass**: `_extensions_window(allow_process_fallback=True)` — if `_extensions_app()` succeeds (app is in AT-SPI tree) but no windows are found after 20s, return `None` (soft pass). No pgrep needed.

6. **DND Shell.Eval**: existing gsettings fallback in `_set_dnd_enabled()` covers GNOME 50; the Shell.Eval path logs TypeError noise but correctly falls through to gsettings.

**Testsuite merge flow (projectbluefin/testsuite):**
- Requires 2 approvals + CI via merge queue
- Enqueue via GraphQL: `gh api graphql -f query="mutation { enqueuePullRequest(input: { pullRequestId: \"${NODE_ID}\" }) { mergeQueueEntry { id position } } }"`
- After merge, update pin in `projectbluefin/bluefin`'s `.github/workflows/post-testing-e2e.yml` line 49 and merge via `gh pr merge N --repo projectbluefin/bluefin --squash --admin`
- Build triggers automatically on push to `main`; e2e triggers as `workflow_run` on "Testing Images" completing

### Testsuite pin management across projectbluefin repos (added 2026-05-31)

**Problem:** Testsuite SHAs drift silently — the same workflow (`e2e.yml`) gets pinned at different commits across workflows in the same repo and across repos. This causes inconsistent behavior and is hard to notice until something breaks.

**Renovate covers this automatically:** `config:best-practices` includes the `github-actions` manager which tracks `uses: owner/repo/.github/workflows/*.yml@sha` pins. No custom manager needed in `renovate.json5`. Renovate opens PRs to bump pins when testsuite advances.

**Exception:** `dakota` was using `@main` (unpinned) — Renovate can only track pins, not floating refs. Any repo using `@main` must be manually pinned first; Renovate will then maintain it.

**Always fetch testsuite before pinning:** The SHA at analysis time may differ from SHA at implementation time. Always run `git -C ~/src/testsuite fetch origin && git -C ~/src/testsuite rev-parse origin/main` immediately before writing pins.

**Pin alignment protocol:**
```bash
NEW=$(git -C ~/src/testsuite rev-parse origin/main)
grep -r "e2e.yml@" /path/to/repo/.github/workflows/ | grep -v "^Binary"
# Update all stale pins to $NEW
```

### projectbluefin e2e workflow pattern (added 2026-05-31)

The standard continuous e2e gate pattern across all projectbluefin image repos:

| Workflow | When | Suites | Image |
|---|---|---|---|
| `post-{build}-e2e.yml` | `workflow_run` after every push to `main` succeeds | `smoke,common` | `:testing` tag |
| `weekly-testing-promotion.yml` | Weekly, before promoting | `developer,vanilla-gnome,software,common` | `@digest` |
| `nightly.yml` | Cron 02:00 UTC daily | `smoke,common,vanilla-gnome` | `:latest` |
| `pr-testsuite.yml` | PR gate | `smoke` | `:lts-testing` |

The `post-build-e2e.yml` continuous gate was **missing from bluefin-lts** until 2026-05-31 (PR #16). All image repos should have this pattern.

**Suites not yet in GHA action (SSH-mode only):** `lifecycle`, `security`, `hardware` — testsuite epics #43/#44.
**Suite `dx`** requires a `dx` image variant in the build matrix; not yet wired.
**Suite `software`** is GHA-ready but only runs at weekly promotion (expensive).

### Mergeraptor automerge — author.login discrepancy (added 2026-05-31)

**Problem:** `renovate-automerge.yml` in both `projectbluefin/bluefin` and `projectbluefin/bluefin-lts` filtered on `author.login == "renovate[bot]"`. However, mergeraptor PRs appear as `author.login == "app/mergeraptor"`. This caused ALL mergeraptor dependency-update PRs to be silently skipped with "No open Renovate PR found for SHA ... — skipping" even when CI passed.

**Fix:** Update the jq filter to accept both:
```jq
select(.author.login == "renovate[bot]" or .author.login == "app/mergeraptor")
```

**Pre-existing LTS issue:** `build-gdx.yml` has been failing on every branch including `main` since at least 2026-05-31. This is a pre-existing build regression unrelated to automerge. It does NOT affect `PR Validation — testsuite` (which is in a separate workflow).

**Two-step dependency for LTS automerge to work:**
1. PR #16 merges (updates stale `12bd892e` pin → `969d471` in `pr-testsuite.yml`)
2. PR #17 merges (adds `app/mergeraptor` to automerge filter)

Once both land, future mergeraptor PRs will pass e2e and get auto-merged.

### PAT policy for projectbluefin (added 2026-05-31)

**PATs are FORBIDDEN in projectbluefin repos.** Never add `RENOVATE_TOKEN` or any PAT secret to workflow files.

Renovate authentication uses the **GitHub App** pattern via `actions/create-github-app-token` with `RENOVATE_APP_ID` + `RENOVATE_PRIVATE_KEY` org secrets — see `projectbluefin/renovate-config` for the canonical workflow.

Renovate runs are kicked off by triggering the self-hosted workflow in `projectbluefin/renovate-config`:
```bash
gh workflow run "Renovate Self-Hosted" --repo projectbluefin/renovate-config
```
Individual repos do NOT need their own `renovate.yml`. Renovate is managed centrally.
