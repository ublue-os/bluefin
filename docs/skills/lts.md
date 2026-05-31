# Bluefin LTS Skill

⚠️ This skill contains critical production warnings. Read before any LTS work.

## When to Use

- Working in the `~/src/bluefin-lts` repo on any change
- Understanding CentOS Stream vs Fedora Silverblue differences
- Validating LTS image changes before committing
- Any question about the LTS ISO status (**answer: DISABLED — do not touch**)

## When NOT to Use

- Standard Fedora-based Bluefin (`bluefin`, `aurora`) — use [docs/skills/build.md](docs/skills/build.md)
- Building or promoting any ISO — LTS ISO is broken; use [docs/skills/iso.md](docs/skills/iso.md) only for HWE

## ⚠️ CRITICAL: ISO Status — DISABLED

**LTS ISOs are currently BROKEN. This is a production safety constraint.**

### What MUST NOT happen:
- DO NOT re-enable the `build-iso-lts.yml` schedule
- DO NOT run `promote-iso.yml` with `variant: lts` or `variant: all`
- DO NOT run `build-iso-all.yml` (it matches `*-lts-*.iso*` and promotes LTS)
- DO NOT remove or alter warning comments in `build-iso-lts.yml`

### Why:
Anaconda does not work correctly on the LTS base image. There are working LTS ISOs
in production R2 from before the breakage. Overwriting them with broken builds would
break LTS users who need to reinstall.

### Current status: Production ISOs safe, new builds blocked.

## How It Works

Bluefin LTS is:
- Built on **CentOS Stream** (not Fedora Silverblue)
- Uses `bootc` for image building
- Targets enterprise/long-term stability use cases
- Available at `~/src/bluefin-lts`

## Remotes

**Canonical repo:** `projectbluefin/bluefin-lts` (migrated from `projectbluefin/bluefin-lts` on 2026-05-30)

```
origin    git@github.com:castrojo/bluefin-lts.git
projectbluefin  git@github.com:projectbluefin/bluefin-lts.git
```

Land changes in `projectbluefin/bluefin-lts`. `castrojo/bluefin-lts` (origin) is a personal fork.

## Key Differences from Regular Bluefin

| Aspect | Bluefin | Bluefin LTS |
|---|---|---|
| Base | Fedora Silverblue | CentOS Stream |
| Packages | Fedora/COPR | CentOS/EPEL |
| Build tool | rpm-ostree | bootc |
| Streams | gts, stable, latest, beta | stable primarily |
| ISOs | Working | **BROKEN — DO NOT PROMOTE** |

## Registry

LTS images publish to **`ghcr.io/projectbluefin/bluefin`** (not a separate `bluefin-lts` package).
Migration from `ghcr.io/projectbluefin/bluefin` completed 2026-05-30.

Query tags with skopeo (requires ghcr.io login):
```bash
gh auth token | skopeo login ghcr.io -u castrojo --password-stdin
skopeo list-tags docker://ghcr.io/projectbluefin/bluefin | python3 -c "
import sys, json
tags = json.load(sys.stdin)['Tags']
print('\n'.join(t for t in tags if 'testing' in t))
"
```

### Tag structure

| Tag pattern | Meaning |
|---|---|
| `lts-testing` | LTS testing (floating, amd64) |
| `lts-testing-amd64` / `lts-testing-arm64` | Arch-explicit |
| `lts-hwe-testing` | LTS HWE testing |
| `stream10-testing` / `10-testing` | CentOS Stream 10 aliases |
| `lts-testing-YYYYMMDD` | Dated snapshot |

**GNOME 50 is the default** as of 2026-05-30. The `*-testing-50` experimental tags are no longer produced (`build-gnome50.yml` deleted).

## Validation

```bash
just check
```

## Learnings

### Promotion Workflow: automated via GitHub Actions

Promotion from `main` to `lts` is fully automated — no manual PR needed.

Push to `main` → GitHub Actions merges `main→lts` automatically.
To publish production images: run `scheduled-lts-release.yml` manually on `lts`:
```bash
gh workflow run scheduled-lts-release.yml --repo projectbluefin/bluefin-lts
```

⚠️ Never commit directly to `lts`. Land changes in `main` first.

---

### NEVER squash-merge promotion PRs (added 2026-03-18)

**What:** PR #1199 showed 19 commits and 6 changed files when only 1 commit was genuinely new. `mergeable_state: dirty` — GitHub couldn't merge it.

**Root cause:** Squash-merge creates orphan commits that permanently freeze the merge base. GitHub computes PR diffs from the merge base (not tree comparison), so all historical commits pile up in every future promotion PR. This compounds: each squash adds another orphan, bloat grows without bound.

**Fix:** Always use **regular merge** ("Create a merge commit") for promotion PRs. Regular merge has two parents → merge base advances → future PRs show only new commits.

**Verified locally:**
| Strategy | After 1 cycle | After 2 cycles | After N cycles |
|---|---|---|---|
| Squash merge | 1 commit ✅ | 2 commits ❌ | N commits ❌ |
| Regular merge | 1 commit ✅ | 1 commit ✅ | 1 commit ✅ |

**One-time fix applied (2026-03-18):** Regular merge of `main → lts` (`d5a0149`) repaired the merge base. The old tree-hash anchor workaround in `create-lts-pr.yml` was removed — `git log lts..main` now works correctly with regular merge.

**Recurrence (2026-04-14):** PR #1271 was squash-merged again (commit `5278d41`), breaking the merge base a second time. Root cause: `allow_squash_merge` is `true` on the repo — nothing prevents it technically. PR #1291 showed 29 commits (16 old + 13 new) and `mergeable_state: dirty`.

**Repair command (confirmed working 2026-04-14):**
```bash
cd ~/src/bluefin-lts
git fetch projectbluefin
git checkout -B lts projectbluefin/lts
git merge -X theirs projectbluefin/main   # accept main's version of all conflicts
git push projectbluefin lts
```
Then cancel any accidentally-triggered build runs — branch repair does not require publishing.

**Don't repeat:** Never "simplify" by switching back to squash-merge. It looks cleaner but breaks the merge base after the first promotion cycle.

---

### Fork sync pattern for castrojo/bluefin-lts

**What:** `castrojo:main` and `projectbluefin:main` diverge in SHA even when content is identical. PRs merged to projectbluefin get a merge commit SHA; the fork has the direct push SHA.

**Why this matters:** Opening a PR from castrojo fork to projectbluefin will show a merge conflict even if content is the same.

**Fix:** Always rebase onto projectbluefin/main before pushing a fix branch:
```bash
git fetch projectbluefin
git rebase projectbluefin/main   # skips already-applied commits automatically
git push origin BRANCH --force-with-lease
```

After a fix PR is merged to projectbluefin, sync the fork:
```bash
git checkout main
git reset --hard projectbluefin/main
git push origin main --force-with-lease
```

**Don't repeat:** Never use `git merge projectbluefin/main` on the fork — it creates a merge commit that makes future rebases messy.

---

### Merge method for bluefin-lts PRs (added 2026-03-31, corrected 2026-04-14)

**What:** GitHub UI defaults to squash merge. `allow_rebase_merge: false` but **`allow_squash_merge: true`** — squash is NOT disabled on this repo (confirmed 2026-04-14). Anyone who clicks "Squash and merge" CAN do so, which breaks the merge base.

**Fix:** Always use the API to guarantee merge commit:
```bash
gh api repos/projectbluefin/bluefin-lts/pulls/NNN/merge \
  --method PUT --field merge_method=merge
```

**Don't repeat:** Always use `merge_method: "merge"`. Squash is allowed by the repo but must never be used for promotion PRs.

**⚠️ Tracking issue:** castrojo/bluefin-lts#TODO — disable squash merge on projectbluefin/bluefin-lts.

---

### publish: false on push to lts branch (added 2026-03-31)

**What:** Merging a promotion PR into `lts` fires the build workflows — but does NOT publish to the registry. `build-regular.yml` gates publish on:
```
publish: ${{ (workflow_dispatch && ref == lts/main) || (push && ref == main) }}
```
Push to `lts` does not publish. Only `workflow_dispatch` on `lts` or push to `main` publish.

**Fix:** After merging a promotion PR, trigger `scheduled-lts-release.yml` manually to publish all 5 builds:
```bash
gh workflow run scheduled-lts-release.yml --repo projectbluefin/bluefin-lts
```
This dispatches all 5 workflows via `workflow_dispatch` on `lts`, which satisfies the publish condition.

**Don't repeat:** Do not assume that merging the promotion PR publishes images. It builds but does not push. Always run the scheduled release manually after any urgent promotion.

---

### Emergency registry rollback pattern (added 2026-03-31)

**When:** A regression is discovered after images are published to floating tags (`lts`, `lts-hwe`, etc.).

**Key insight:** Dated tags (`lts.20260324`, `lts-hwe.20260324`) are immutable and never overwritten. They are the rollback targets. The registry retains them indefinitely.

**Complete tag checklist — ALL tags must be rolled back. Audit conducted 2026-03-31.**

### Tags with dated snapshots (rollback possible)

| Image | Floating tag | Rollback target |
|---|---|---|
| `ghcr.io/projectbluefin/bluefin` | `lts` | `lts.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin` | `lts-hwe` | `lts-hwe.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin` | `lts-amd64` | copy from `lts.YYYYMMDD` (same image, amd64 only) |
| `ghcr.io/projectbluefin/bluefin` | `lts-hwe-amd64` | copy from `lts-hwe.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin-dx` | `lts` | `lts.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin-dx` | `lts-hwe` | `lts-hwe.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin-dx` | `lts-amd64` | copy from `lts.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin-dx` | `lts-hwe-amd64` | copy from `lts-hwe.YYYYMMDD` |
| `ghcr.io/projectbluefin/bluefin-gdx` | `lts` | `lts.YYYYMMDD` (check skopeo list-tags — publishes less frequently) |
| `ghcr.io/projectbluefin/bluefin-gdx` | `lts-amd64` | copy from `lts.YYYYMMDD` (gdx date) |

### Tags with NO dated snapshots (arm64 — cannot roll back)

| Image | Tag | Status |
|---|---|---|
| `ghcr.io/projectbluefin/bluefin` | `lts-arm64` | **No dated snapshots exist. No rollback path.** |
| `ghcr.io/projectbluefin/bluefin` | `lts-hwe-arm64` | **No dated snapshots exist. No rollback path.** |
| `ghcr.io/projectbluefin/bluefin-dx` | `lts-arm64` | **No dated snapshots exist. No rollback path.** |
| `ghcr.io/projectbluefin/bluefin-dx` | `lts-hwe-arm64` | **No dated snapshots exist. No rollback path.** |
| `ghcr.io/projectbluefin/bluefin-gdx` | `lts-arm64` | **No dated snapshots exist. No rollback path.** |

**Why:** The arm64 tags are pushed by a separate `ubuntu-24.04-arm` runner in `reusable-build-image.yml` (line 255: `podman tag ... :${DEFAULT_TAG}-${PLATFORM}`). The `docker/metadata-action` step only stamps dated tags for `DEFAULT_TAG` (e.g. `lts`, `lts-hwe`), not for the per-arch variant. The arm64 tags are never snapshotted.

**Mitigation:** After a regression, accept that arm64 users on `lts-arm64` cannot be rolled back via skopeo. The fix-forward (publishing a corrected build) is the only recovery path for arm64.

**Rollback command (repeat for each row above):**
```bash
GHCR_TOKEN=$(gh auth token)
skopeo copy \
  --src-no-creds \
  --dest-creds "castrojo:${GHCR_TOKEN}" \
  docker://ghcr.io/projectbluefin/IMAGE:FLOATING_TAG.YYYYMMDD \
  docker://ghcr.io/projectbluefin/IMAGE:FLOATING_TAG
```

**Rollback is always reversible:** The broken dated tag (e.g. `lts.20260331`) remains in the registry. To re-promote, run the same `skopeo copy` in reverse direction.

**Verify after each rollback:**
```bash
skopeo inspect --no-creds docker://ghcr.io/projectbluefin/IMAGE:FLOATING_TAG \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print('Digest:', d['Digest']); print('Created:', d['Created'])"
```
`Created` timestamp must match the known-good date. Run this for all 5 tags before declaring rollback complete.

**gdx caveat:** `bluefin-gdx` publishes less frequently and may not have a dated tag matching the same date as `bluefin` and `bluefin-dx`. Check `skopeo list-tags --no-creds docker://ghcr.io/projectbluefin/bluefin-gdx` to find the last good tag before the regression date.

**GDM failure / SELinux root cause (2026-03-31):** The GNOME 49→50 upgrade introduced a GDM failure (issue 1247) because `selinux-policy` 42.x (EL10 base) lacks policy rules for GDM's new `systemd-userdb` Varlink socket architecture. Fix: upgrade `selinux-policy` + `selinux-policy-targeted` to 43.x from COPR before GNOME group install. This was in PR 1242 (hanthor).

---

> **Resolved issues (GitHub Releases bugs, SBOM Pipeline, Race condition in scheduled-lts-release.yml):**
> `cat

---

### Squash-merge auto-repair guard — HISTORICAL (2026-05-30: create-lts-pr.yml deleted)

`create-lts-pr.yml` was **deleted** during the migration to `projectbluefin/bluefin-lts`.
Promotion from `main→lts` is now fully automated by GitHub Actions (no manual PR).
The squash-merge guard, auto-repair logic, and related history below are kept for reference only.

The squash-merge risk still applies to any manually-opened `main→lts` PRs. If you ever need to manually repair the merge base:
```bash
cd ~/src/bluefin-lts
git fetch projectbluefin
git checkout -B lts projectbluefin/lts
git merge -X theirs projectbluefin/main
git push projectbluefin lts
```

## Ghost Lab Testing

PR changes to bluefin-lts are tested on `titan-lts` — a KubeVirt VM on ghost (192.168.1.102) running `ghcr.io/projectbluefin/bluefin:lts-hwe`.

**Test workflow:**
```bash
# 1. Build test image (layer PR changes on top of lts-hwe)
# On ghost:
sudo podman build -t localhost/bluefin-lts:pr-<N>-test /tmp/build-context/

# 2. Rebuild titan-lts disk from test image
sudo podman run --rm --privileged \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v ~/VMs/titans/image:/output \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type raw --rootfs xfs localhost/bluefin-lts:pr-<N>-test

# 3. Deploy VM with injected disk

# 4. Run verification report
cd  && python3 lab-cli.py run --target lts
```

**Canonical template:** `skills/ghost-testlab/report-template.md` → Bluefin LTS Example section.
Edit structure there; this section reflects the lts-specific field mapping.

**LTS header fields:**

| Field | LTS value |
|---|---|
| **Target** | `bluefin-lts` |
| **VM/Host** | `titan-lts` (NodePort 30220 on ghost) |
| **Image** | `ghcr.io/projectbluefin/bluefin:{tag}` + short digest |

**Section structure:** System Identity → bootc Status → Desktop → Services → GNOME Extensions → Packages → Regression Canaries → Kernel → Custom Assertions

Generated by: `lab-cli.py run --target lts`

**Trailer:**
```
<!-- status:{PASS|FAIL} target:lts label:{label} digest:{digest} -->
```

**Header lines (in order):**
```
## ⚡ Vanguard Lab Strike Report: {hostname}
**Alpha**: Blue Universal CI Companion · Iron Lord Archive · Long Watch Protocol
**Guardian on Duty**: `castrojo` on Ghost Homelab

*"{flavor text}"*
```

**Verdict line:**
- GO: `🟢 GO — {summary}`
- NOGO: `🔴 NOGO — {summary}`

**⚠️ NEVER use `bootc switch` inside the VM to test local unsigned images.** The `policy.json` requires signatures for all images. Always use BIB to rebuild the disk.

**Report must be posted to the PR** before merging. Post with `add_issue_comment` MCP or `gh pr comment`.

---

### Adding a GNOME Shell Extension (added 2026-05-23)

**Pattern:** All extensions are **git submodules** in `system_files/usr/share/gnome-shell/extensions/<UUID>/`. Renovate tracks digest updates automatically via the `git-submodules` manager.

**Steps to add an extension:**
1. Find the UUID from the extension's `metadata.json` (`.uuid` field)
2. `git submodule add <upstream-repo-url> system_files/usr/share/gnome-shell/extensions/<UUID>`
3. In `build_scripts/21-build-gnome-extensions.sh`, add a `glib-compile-schemas --strict ...` step
4. If the extension needs dconf overrides: also `install -Dm644 <schema.xml> /usr/share/glib-2.0/schemas/` so the system schema DB includes it
5. Create `system_files/etc/dconf/db/distro.d/<NN>-bluefin-lts-<name>` with dconf keyfile

**Steps to remove an extension:**
1. `git submodule deinit -f system_files/usr/share/gnome-shell/extensions/<UUID>`
2. `git rm system_files/usr/share/gnome-shell/extensions/<UUID>` (also cleans `.gitmodules`)
3. Remove the build script section for that extension
4. Remove the dconf keyfile if one exists

**Validate:** `just check && just lint` — both must exit 0 before committing.

---

### LogoMenu → Custom Command Menu transition (added 2026-05-23)

**Status:** In progress. `logomenu@aryan_k` was removed from LTS in PR #1367. `custom-command-list@storageb.github.com` was added as a replacement.

**What common still ships:** `projectbluefin/common` delivers `04-bluefin-logomenu-extension` (dconf config for Logo-menu) and the `logomenu@aryan_k` submodule. Until common is updated:
- The orphaned `04-bluefin-logomenu-extension` keys from common are a **no-op** — logomenu is not installed in LTS
- `missioncenter-helper` and `distroshelf-helper` binaries are gone from LTS; app launches use `flatpak run` directly
- LTS owns its own dconf keyfile: `system_files/etc/dconf/db/distro.d/05-bluefin-lts-custom-command-menu`

**Cleanup trigger:** Once `projectbluefin/common` removes logomenu and adds custom-command-menu:
1. `git rm system_files/etc/dconf/db/distro.d/05-bluefin-lts-custom-command-menu`
2. Remove the Custom Command Menu build step from `21-build-gnome-extensions.sh`
3. Remove the `custom-command-list@storageb.github.com` submodule (LTS will inherit from common)

---

### Merge Queue (added 2026-05-23)

`projectbluefin/bluefin-lts` `main` branch uses a **merge queue**. PRs cannot be force-merged via `gh pr merge` or GitHub MCP — both return "The merge strategy for main is set by the merge queue."

**How to merge:** Approve the PR, then it enters the queue and merges automatically once CI passes. `gh pr merge --auto` enqueues it. The merge queue runs CI before merging.

**Implication:** Never promise "merged" to the user — say "queued" and let CI run.

---

### Session changes 2026-05-30

- **GNOME 50 is now the default.** GNOME 49-specific code paths were removed from the build scripts.
- **`build-gnome50.yml` was deleted.** The experimental `*-testing-50` tags (`lts-testing-50`, `lts-hwe-testing-50`, `stream10-testing-50` / `10-testing-50`) are no longer produced.
- **`content-filter.yaml` was deleted.** The spammy issue-comment action is gone.
- **`pr-testsuite.yml` now runs e2e smoke tests** via `projectbluefin/testsuite` on every PR against `lts-testing`. This is informational coverage only — `Lint & syntax` remains the only required check.
- **GDX now supports `FEDORA_AKMODS_VERSION`.** Default is `43`; override it when the NVIDIA akmods repo version needs to be pinned differently.

---

### SBOM Policy — Aurora parity (added 2026-05-23)

LTS does **not** add independent SBOM generation. We stay in parity with Aurora's approach. PR #1360 (hanthor, attach SBOMs to releases) was closed for this reason. Revisit when Aurora ships its SBOM implementation — both products should ship the same pattern at the same time.

---

### Session changes 2026-05-31 — zstd:chunked improvements (PR #19)

**Podman upgrade step (arm64-only → both arches):**
The old `Install dependencies` step only ran `apt install podman` on `arm64`. Ubuntu 24.04 podman on amd64 is also too old — it silently drops `ostree.components` annotations needed by chunkah, and mishandles zstd:chunked pushes. Replaced with full resolute (Ubuntu 25.04) upgrade for BOTH arches:
```bash
IDV=$(. /usr/lib/os-release && echo ${ID}-${VERSION_ID})
test "${IDV}" = "ubuntu-24.04"
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
  mirror="http://azure.archive.ubuntu.com/ubuntu"
else
  mirror="http://ports.ubuntu.com/ubuntu-ports"
fi
echo "deb ${mirror} resolute universe main" | sudo tee /etc/apt/sources.list.d/resolute.list
sudo apt update && sudo apt install -y --allow-downgrades crun/resolute buildah/resolute podman/resolute skopeo/resolute
```

**Double-push pattern + `--force-compression` + `--compression-level 3`:**
- `--force-compression` was already present in LTS (good) — ensures gzip blobs are re-compressed, not reused
- Added `--compression-level 3` (default 6 is 2× slower for ~0.1% size difference)
- Added double-push: first push uploads layers, second push captures `--digestfile` for stable cosign signing
- `--digestfile` must be on the **second** push

**bootc unified storage service:**
`system_files/usr/lib/systemd/system/bootc-unified-storage.service` added, enabled in `build_scripts/40-services.sh`. Runs `bootc image set-unified` once on first boot. Uses `ConditionPathExists=!/var/lib/.bootc-unified-storage` as a sentinel + `Restart=on-failure`. Local operation — no network needed. LTS uses XFS which supports reflinks for efficiency.

<!-- Background agents append here automatically -->
