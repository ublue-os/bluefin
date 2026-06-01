# THEPATTERN — Technical Comparison Report

## `projectbluefin/bluefin` vs `ublue-os/bluefin`

> Comparing default (`main`) branches. Data sourced 2026-05-31 via GitHub API.
> `ublue-os/bluefin` = baseline. `projectbluefin/bluefin` = subject.

---

## 1. Repository Method Comparison

| Aspect | `ublue-os/bluefin` | `projectbluefin/bluefin` |
|--------|-------------------|--------------------------|
| **Repo size (GitHub)** | 434,267 KB (full legacy history) | 330 KB (fresh repo, no legacy) |
| **Tracked files** | 71 | 88 |
| **Workflow files** | 10 | 16 |
| **Base image** | `ghcr.io/ublue-os/silverblue-main` (ublue reprocessed, F42) | `quay.io/fedora-ostree-desktops/silverblue` (Fedora direct, F43, digest-pinned) |
| **Stream model** | Branch-push (`stable`, `latest`, `beta`) | Testing→E2E→weekly promotion→`stable` |
| **PR validation** | Full image build | Dedicated `pr-validation.yml` with path-filtering |
| **Signing** | Key-based (cosign `--key env://COSIGN_PRIVATE_KEY`, `cosign.pub` in repo) | Keyless (cosign via OIDC — no secrets, no key file) |
| **Multi-arch** | x86_64 only | Input wired (disabled: `# FIXME: enable when akmods has ARM`) |
| **Push strategy** | Push each tag via podman | Two-push pattern + `skopeo copy` server-side tag copies |
| **Runner Podman** | Stock Ubuntu 24.04 | Upgraded from Ubuntu 25.04 resolute (annotation fix) |
| **Just install** | Homebrew on runner | `taiki-e/install-action` (faster, no brew dep) |
| **PR rechunk** | Always rechunks | Skips rechunk; exports OCI dir for local testing |
| **Digest output** | None | `collect-digests` job aggregates per-image digests |
| **Desktop testing** | None | E2E via `projectbluefin/testsuite` (QEMU + AT-SPI) |
| **Renovate** | Org-level config (hosted) | Self-hosted via `projectbluefin/renovate-config` + automerge workflow |

### Containerfile

Near-identical architecture (ublue: 48 lines, projectbluefin: 47 lines): multi-stage build from `common` + `brew` OCI layers → single `RUN --mount` build step → `bootc container lint`.

**Critical difference:** The base image source diverges:
- `ublue-os`: `FROM ghcr.io/ublue-os/silverblue-main:42` — depends on ublue's own reprocessed upstream image
- `projectbluefin`: `FROM quay.io/fedora-ostree-desktops/silverblue:43@sha256:...` — builds directly on Fedora's official image with a digest pin

This eliminates a dependency on the `ublue-os/main-images` pipeline and gives projectbluefin full control over its supply chain. The digest pin in the Containerfile ARG (managed by Renovate) ensures reproducibility without an intermediate reprocessing layer.

---

## 2. Feature Differences

### Workflows added in `projectbluefin/bluefin`

| Workflow | Lines | Status |
|----------|:-----:|--------|
| `build-image-testing.yml` | 34 | ✅ Running, green |
| `post-testing-e2e.yml` | 52 | ✅ Running (last run: failed) |
| `weekly-testing-promotion.yml` | 197 | ✅ Running |
| `e2e-dispatch.yml` | 161 | ✅ Triggered (skips when no matching event) |
| `cherry-pick-to-stable.yml` | 48 | ✅ Present on main |
| `renovate-automerge.yml` | 49 | ✅ Running, recently fixed (#51) |
| `pr-validation.yml` | 44 | ✅ Required for merge queue |

### Removed vs baseline

| Removed | Notes |
|---------|-------|
| `build-image-beta.yml` | Beta stream eliminated |
| `cosign.pub` | Keyless = no public key file |
| `ublue-os/silverblue-main` dependency | Builds on Fedora direct — eliminates ublue-os/main-images pipeline dependency |

### System files added (image-level customizations)

- `etc/dconf/db/distro.d/04-bluefin-custom-command-menu`
- `usr/bin/rechunker-group-fix` + systemd service
- `usr/share/dnf/plugins/copr.vendor.conf`
- `usr/share/flatpak/preinstall.d/bazaar.preinstall`
- 3 SVG icons (ampere, framework, ublue logos)
- `usr/share/ublue-os/just/60-custom.just`

### LTS comparison (`bluefin-lts`)

| Aspect | `ublue-os/bluefin-lts` | `projectbluefin/bluefin-lts` |
|--------|:----------------------:|:----------------------------:|
| Workflows | 14 files / 1,376 lines | 11 files / 1,175 lines |
| Multi-arch | ✅ amd64+arm64 | ✅ amd64+arm64 |
| Signing | Key-based | Keyless |
| Extra workflows | `build-gnome50`, `create-lts-pr`, `content-filter` | Removed/consolidated |
| Containerfile | 45 lines | 47 lines |
| Justfile | 412 lines | 413 lines |

---

## 3. Testsuite — Automated Desktop QA

### What it is

[`projectbluefin/testsuite`](https://github.com/projectbluefin/testsuite) — created 2026-05-25, 88 merged PRs in 6 days (103 total PRs).

> "Cloud-native QA pipeline for Project Bluefin — Argo Workflows + KubeVirt + qecore/behave AT-SPI tests"

**Key property:** Runs on standard `ubuntu-latest` GitHub Actions runners. No self-hosted hardware. The OCI image boots in a KVM-accelerated QEMU VM, a GNOME session starts, and behave tests exercise it via AT-SPI accessibility tree and SSH.

### Test stack

| Layer | Tool | Purpose |
|-------|------|---------|
| BDD runner | behave | Gherkin `.feature` scenarios |
| Session bridge | qecore-headless | Wayland/DBus session bootstrap in QEMU |
| GUI automation | dogtail (AT-SPI) | Accessibility-tree clicks, reads, asserts |
| Shell bridge | `org.gnome.Shell.Eval` | GNOME 50+ JS eval for top-bar/overview |
| VM runtime | QEMU + KVM | Boots OCI image as real VM on GHA runners |

### Test coverage — 255 scenarios across 12 suites

| Suite | Scenarios | Validates |
|-------|:---------:|-----------|
| `smoke` | 82 | GNOME Shell (AT-SPI tree, top bar, Activities, Quick Settings, lock screen, workspaces), app launches (Firefox, Files, Calculator, Settings, Text Editor), regressions |
| `common` | 32 | Shell env (fzf, starship), dconf/GSettings defaults, desktop entries |
| `developer` | 19 | Homebrew (version, list, info, search, doctor, install round-trip), Podman |
| `dx` | 15 | Developer Experience tools layer |
| `software` | 12 | Flatpak operations |
| `vanilla-gnome` | 12 | GNOME core without Bluefin customizations |
| `bazzite` | 20 | Bazzite-specific extensions and shell |
| `nvidia` | 12 | GPU driver and runtime |
| `security` | 15 | Image provenance, SELinux |
| `lifecycle` | 13 | bootc upgrade/rollback |
| `hardware` | 10 | Peripheral detection |
| `flatcar` | 13 | Boot and lifecycle |

*Source: [`tests/`](https://github.com/projectbluefin/testsuite/tree/main/tests) — `.feature` files*

### How it integrates with the build pipeline

```
push to main
    │
    ▼
build-image-testing.yml ──► images built, digests uploaded as artifacts
    │
    ▼ (workflow_run trigger, on success + push event)
post-testing-e2e.yml ──► downloads digest, calls testsuite
    │                     uses: projectbluefin/testsuite/.github/workflows/e2e.yml@<pinned-sha>
    │                     suites: smoke
    ▼
weekly-testing-promotion.yml (Tuesday 06:00 UTC)
    ├── verify-e2e: finds passing post-testing-e2e run for locked main HEAD
    │   └── if NOT found → FAIL (refuses to promote untested code)
    ├── run extended suites: developer, vanilla-gnome
    └── fast-forward stable/latest branches on success
```

On-demand: maintainers comment `/e2e` on any PR → builds PR image → runs smoke + developer + vanilla-gnome → posts results.

*Sources:*
- [`post-testing-e2e.yml:47`](https://github.com/projectbluefin/bluefin/blob/main/.github/workflows/post-testing-e2e.yml) — `uses: projectbluefin/testsuite/.github/workflows/e2e.yml@05445e0`
- [`weekly-testing-promotion.yml:38-64`](https://github.com/projectbluefin/bluefin/blob/main/.github/workflows/weekly-testing-promotion.yml) — locks SHA, queries e2e conclusion, exits 1 if not `success`
- [`e2e-dispatch.yml`](https://github.com/projectbluefin/bluefin/blob/main/.github/workflows/e2e-dispatch.yml) — `/e2e` PR comment trigger

### What this prevents (vs `ublue-os/bluefin` which has zero automated desktop testing)

| Risk | Example | ublue-os detection | projectbluefin detection |
|------|---------|:------------------:|:------------------------:|
| Shell crash on boot | Extension conflicts (`#4612`) | User reports post-release | `@regression @bluefin_4612` in smoke |
| Lock screen broken | Extension hides unlock | User reports post-release | `@lock_screen` scenario pre-promotion |
| Brew broken PATH | Bad `/etc/environment` | User reports post-release | `@brew_version` + `@brew_install` in developer |
| GSettings defaults wrong | dconf override missing | User reports post-release | `common_dconf.feature` in smoke |
| bootc upgrade regression | Bad image metadata | Manual testing | `lifecycle/bootc.feature` |
| Broken image ships to stable | Upstream dep fails | **Currently happening** | Promotion blocked — verify-e2e gate |

### Current operational status

| Aspect | Status |
|--------|--------|
| Smoke suite gating main→stable | ✅ Operational (pinned at `05445e0`) |
| Weekly promotion with e2e verification | ✅ Operational |
| `/e2e` PR dispatch | ✅ Wired |
| `@quarantine` tagged scenarios | Many — tests written but not yet stable enough to block promotion |
| Testsuite repo CI | ✅ All green |

---

## 4. Local Developer Experience

### Validation tooling comparison

| Tool | `ublue-os/bluefin` | `projectbluefin/bluefin` |
|------|:------------------:|:------------------------:|
| **pre-commit hooks** | 5 basic hooks (v4.4.0) | 8 hooks + `actionlint` (v4.6.0) |
| **Shellcheck** | ❌ | ✅ Runs in PR validation CI |
| **Actionlint** | ❌ | ✅ Via pre-commit hook |
| **PR CI gate** | Full image build (~40 min) | `pr-validation.yml` lint job (~1–2 min); full build only if image paths changed |
| **Merge queue** | ✅ (branch protection) | ✅ (requires `validate` status) |

### `pre-commit run --all-files` comparison

**`ublue-os/bluefin`** (5 hooks):
```yaml
- check-json
- check-toml
- check-yaml
- end-of-file-fixer
- trailing-whitespace
```

**`projectbluefin/bluefin`** (9 hooks):
```yaml
- check-json (excl .devcontainer.json)
- check-toml
- check-yaml
- end-of-file-fixer
- trailing-whitespace
- check-merge-conflict
- detect-private-key
- check-added-large-files
- actionlint
```

### Local build loop

Both repos use the same `just build` recipe pattern:

```bash
# Local build (identical interface)
just build bluefin latest main

# CI build (identical interface, requires sudo)
sudo just build-ghcr bluefin testing main
```

`projectbluefin/bluefin` adds:
- `just check` — validates all `.just` file syntax
- `just fix` — auto-formats `.just` files
- PR validation runs `just check && shellcheck build_files/**/*.sh && pre-commit run --all-files` in ~2 minutes (vs 40-minute full build)

### Developer workflow difference

| Step | `ublue-os/bluefin` | `projectbluefin/bluefin` |
|------|-------------------|--------------------------|
| Pre-push validation | `pre-commit run` (basic) | `just check && pre-commit run --all-files` (lint + actionlint + shellcheck) |
| PR feedback time | ~40 min (full image build) | ~2 min (`pr-validation.yml`) + optional full build if image paths changed |
| PR testing | Build artifact only | OCI dir artifact + `/e2e` command for desktop testing |
| Merge requirement | Build passes | `validate` job passes (fast) + build passes (if paths changed) |

---

## 5. SLOC Analysis — Three-Column Comparison

### `bluefin` (Fedora-based)

| Component | `ublue-os/bluefin` | `projectbluefin/bluefin` (current) | After `projectbluefin/actions` |
|-----------|:------------------:|:----------------------------------:|:------------------------------:|
| **Workflows** | 729 (10 files) | 1,365 (16 files) | **~1,151** (16 files) |
| ↳ `reusable-build.yml` | 332 | 422 | **~208** |
| Containerfile | 48 | 47 | 47 |
| Justfile | 762 | 708 | 708 |
| build_files | 1,132 | 1,224 | 1,224 |
| **CI+Build subtotal** | **2,671** | **3,344** | **~3,130** |
| **Δ vs baseline** | — | +673 (+25%) | **+459 (+17%)** |
| system_files (image content) | 349 | 729 | 729 |
| **Grand total** | **3,020** | **4,073** | **~3,859** |

### What the +636 workflow lines buy

| Added capability | Lines | What it does |
|-----------------|:-----:|--------------|
| `weekly-testing-promotion.yml` | 197 | E2E-verified weekly stable promotion |
| `e2e-dispatch.yml` | 161 | On-demand `/e2e` PR testing |
| `post-testing-e2e.yml` | 52 | Auto-triggers smoke after every build |
| `renovate-automerge.yml` | 49 | Auto-merges passing dep updates |
| `cherry-pick-to-stable.yml` | 48 | Hotfix automation |
| `pr-validation.yml` | 44 | Fast lint gate (1–2 min vs 40 min full build) |
| `build-image-testing.yml` | 34 | Smart path-filtered builds |
| Additional in `reusable-build.yml` | +90 | Telemetry, OCI export, digest collection, podman upgrade |
| **Total new capability** | **~675** | Each file = distinct pipeline capability |

### `reusable-build.yml` — projected section replacement (estimated, not yet validated)

| Action | Lines removed | Lines added (`uses:` + inputs) | Net |
|--------|:------------:|:------------------------------:|:---:|
| `setup-runner` | 7 | 5 | −2 |
| `dnf-cache` | 55 | 11 | −44 |
| `rechunk` | 26 | 7 | −19 |
| `generate-tags` | 28 | 8 | −20 |
| `push-image` | 80 | 8 | −72 |
| `sign-and-publish` | 63 | 6 | −57 |
| **Total** | **259** | **45** | **−214** |

**After adoption (estimated):** `reusable-build.yml` drops from 422 → **~208 lines** (−51%). This is a projection based on replacing identified sections with action calls; not yet implemented or validated in production.

### `bluefin-lts` (CentOS-based)

| Component | `ublue-os/bluefin-lts` | `projectbluefin/bluefin-lts` (current) | After actions (est.) |
|-----------|:----------------------:|:--------------------------------------:|:--------------------:|
| Workflows | 1,376 (14 files) | 1,175 (11 files) | **~961** |
| ↳ `reusable-build-image.yml` | 573 | 583 | **~369** |
| Containerfile | 45 | 47 | 47 |
| Justfile | 412 | 413 | 413 |
| **CI+Build Total** | **1,833** | **1,635** | **~1,421** |
| **Δ vs baseline** | — | −198 (−11%) | **−412 (−22%)** |

### Cross-repo savings when `projectbluefin/actions` is consumed (projected)

| Metric | Current state | After actions adoption |
|--------|:-------------:|:----------------------:|
| `bluefin` workflow SLOC | 1,365 | ~1,151 (−214) |
| `bluefin-lts` workflow SLOC | 1,175 | ~961 (−214) |
| **Combined per-repo savings** | — | **~428 lines removed from workflows** |
| Shared actions (maintained centrally) | 0 | 801 lines |
| **Per-repo workflow surface** | 1,270 avg | **~1,056 avg** (−17%) |

> Note: This reduces per-repo workflow maintenance surface, not total org code. The 801 lines move into a shared repo maintained once rather than duplicated.

### If `ublue-os/bluefin` adopted the same actions

| | Current | After actions |
|--|:-------:|:-------------:|
| `reusable-build.yml` | 332 | **~161** (−171) |
| Total workflows | 729 | **~558** (−23%) |

---

## 6. Sustainability & Maintenance

### ✅ Implemented and operational

| Capability | Evidence |
|------------|----------|
| **Fedora-direct base image** | Containerfile: `quay.io/fedora-ostree-desktops/silverblue:43@sha256:...` — no ublue-os/main-images dependency |
| Keyless signing | No `cosign.pub`, no `SIGNING_SECRET` in workflows |
| E2E gating | `post-testing-e2e.yml` → testsuite pin `@05445e0` |
| Weekly promotion | `weekly-testing-promotion.yml` — refuses to promote without passing e2e |
| Merge queue | Branch protection requires `validate` status |
| Path-filtered PR builds | `dorny/paths-filter` in `build-image-testing.yml` |
| Renovate automerge | Operational, patched for mergeraptor (#51) |
| PR OCI artifacts | `podman save --format oci-dir` for local `bootc switch` testing |
| Declarative version pins | `image-versions.yml` — structured Renovate target (digest-pinned) |
| Fast PR validation | `pr-validation.yml` — shellcheck + actionlint + pre-commit (~1–2 min) |
| Build telemetry | Duration tracking for build/rechunk/push in step summary |
| Self-hosted Renovate | `projectbluefin/renovate-config` — GitHub App auth, no PATs |

### ❌ Defined but NOT consumed (aspirational)

| Capability | Status | Projected benefit |
|------------|--------|-------------------|
| `projectbluefin/actions` (9 actions, 801 lines) | **Zero consumers** | −214 lines/repo, −428 org-wide |
| ARM builds | Input wired, commented out | Multi-arch when akmods ready |

### Operational health (sampled 2026-05-31)

| Repo | Status | Notes |
|------|--------|-------|
| `ublue-os/bluefin` stable builds | ❌ Last 5 runs: 4 failed, 1 action_required | May be temporary (upstream dep) |
| `projectbluefin/bluefin` testing builds | ✅ Last 5 runs: 4 succeeded, 1 cancelled | |
| `projectbluefin/bluefin` post-testing-e2e | ⚠️ Last completed run: FAILED | Test suite stabilizing |

> projectbluefin's promotion model means a failing e2e **blocks** untested images from reaching stable. ublue-os lacks an automated desktop E2E gate — failures are caught at build time or by users, depending on failure mode.

---

## 7. Conclusions

### Classification of work

| Category | Contents |
|----------|----------|
| **Implemented & operational** | Keyless signing, e2e gating, weekly promotion, PR path-filtering, renovate automerge, fast PR validation, build telemetry, OCI artifacts, merge queue |
| **Implemented, currently failing** | post-testing E2E (test suite stabilizing) |
| **Aspirational / unrealized** | `projectbluefin/actions` consumption (−214 lines/repo), ARM builds |

### Summary scorecard

| Criterion | Assessment |
|-----------|-----------|
| **Supply chain independence** | projectbluefin — builds on Fedora direct, no ublue-os/main-images dep |
| **Pipeline maturity** | projectbluefin — testing→e2e→promotion lifecycle |
| **Security** | projectbluefin — keyless signing, `detect-private-key` hook |
| **Quality assurance** | projectbluefin — 255-scenario desktop test suite, promotion gate |
| **Developer velocity** | projectbluefin — 2-min PR validation vs 40-min full build |
| **Operational resilience** | projectbluefin — stable protected from upstream breakage by design |
| **Code economy (today)** | ublue-os — 2,671 vs 3,344 CI+build lines (+25% in projectbluefin) |
| **Code economy (after actions)** | Closer — 2,671 vs ~3,130 (+17%) |
| **Reusability (actual)** | Neither — actions exist but aren't wired |
| **Reusability (potential)** | projectbluefin — building blocks ready, −214/repo on adoption |
| **LTS specifically** | projectbluefin — already leaner (−11%), −22% after actions |

### Bottom line

`projectbluefin/bluefin` trades +25% more CI/build code for:
- **Eliminated upstream dependency** — builds on Fedora direct, not ublue-os/main-images
- **Automated desktop testing** (255 scenarios, no self-hosted hardware)
- **Promotion gates** that prevent untested images from reaching users
- **1–2 minute PR lint feedback** instead of 40-minute full builds for non-image changes
- **Keyless signing** that eliminates secret management
- **A clear path to −15% overhead** once shared actions are wired (today: aspirational)

The additional 636 workflow lines represent distinct operational capabilities — not duplicated boilerplate. The `projectbluefin/actions` repo (801 lines, 9 actions) would reduce per-repo workflow surface by ~214 lines each, but **is not consumed today** — its code-saving value is projected, not proven. The primary delivered value is architectural: an independent supply chain building directly on Fedora, a testing-first promotion model, and keyless signing that eliminates secret management entirely.
