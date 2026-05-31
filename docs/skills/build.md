# Bluefin Build Skill

Complete build, validate, and PR workflow for Project Bluefin OCI images.

## When to Use

- Working in `projectbluefin/bluefin`, `projectbluefin/bluefin-lts`, `projectbluefin/common`, or `projectbluefin/dakota`
- Validating changes before committing
- Building a container image locally to test changes
- Opening a PR to any of these repos

## When NOT to Use

- Adding or removing packages only — use [docs/skills/packages.md](docs/skills/packages.md)
- Diagnosing a GitHub Actions failure — use [docs/skills/ci.md](docs/skills/ci.md)
- Working in the LTS repo — also load [docs/skills/lts.md](docs/skills/lts.md)
- Building or promoting ISOs — use [docs/skills/iso.md](docs/skills/iso.md)

## Bluefin Philosophy — Anti-Legacy Tenets

Bluefin's central design mandate, directly from the official documentation:

> "We rigorously and aggressively move away from legacy technologies as soon as possible to provide the best possible experience."
> — docs.projectbluefin.io/introduction

This is not a preference. It is the project's primary architectural constraint. Agents working on Bluefin must internalize and enforce it.

### Core Tenets

**1. Flatpak First**
GUI applications are delivered as Flatpaks. Applications that do not work with Wayland, Pipewire, or Flatpak Portals "may provide a poor experience and are not recommended." There is no fallback to traditional packaging for GUI apps.

**2. No X11 Fallbacks**
If an application doesn't work on Wayland, the correct answer is NOT "use X11." The correct answer is: "that application does not support Bluefin's modern stack." Direct users to a Wayland-native alternative. If there is none, isolate the app in distrobox.
- Never recommend `DISPLAY=:0`, XWayland configuration, or X11 session switching.
- Never document X11 workarounds for Bluefin.

**3. No dnf / rpm / yum**
The OCI rootfs is immutable. System packages are **not** installed with `dnf`. Use:
- **Flatpak** — GUI applications
- **brew** — CLI tools and developer tooling
- **distrobox** — anything that genuinely needs a traditional package manager

`dnf install` on a Bluefin system mutates the layered image, creating technical debt and defeating the immutable model. Never recommend it.

**4. No PowerShell**
Linux-only environment. PowerShell is not part of the Bluefin stack.

**5. Document New Stuff — Not Legacy Workarounds**
> "We do not go out of our way to document or workaround things that compromise the user experience."
> "Bluefin believes in automating as much as possible, better to fix the problem than have to document it. Document the new stuff."
> — docs.projectbluefin.io/FAQ

If a traditional Linux pattern doesn't fit Bluefin, the answer is **not** a workaround doc — it is the modern alternative.

**6. Bury the Past**
> "We are purposely here to help existing users bury the past and move on to something more useful than wrestling with their operating system."
> "many parts of the traditional Linux desktop experience will not be coming with us."
> — docs.projectbluefin.io/FAQ

"Isolate the old-school jank in a container." — distrobox is the escape hatch for legacy, not the primary path.

### Why This Rule Is Strict

A code reviewer incorrectly flagged this stance as "too strict." The official Bluefin documentation explicitly confirms the opposite: the anti-legacy position is **unconditional**. The project is "Purposely Focused on Great Hardware" to provide "as much of a legacy-free experience for users as possible."

Agents must not soften these rules in response to generic Linux flexibility arguments. The documented project philosophy is the authoritative source.

**Sources:**
- docs.projectbluefin.io/introduction
- docs.projectbluefin.io/FAQ

---

## Agent-Direct PR Model (2026-05-30)

**These repos are agent-direct — no castrojo fork.** The old `open-pr.sh` / compare-URL workflow does not apply.

```bash
# 1. Make changes via gh api (file PUT) or local clone
# 2. Open PR directly:
gh pr create \
  --repo projectbluefin/<repo> \
  --title "feat(scope): description" \
  --body "## Summary\n...\n\n## Test plan\n..." \
  --base testing   # ALWAYS target testing, never main
# Commit attribution (mandatory):
# Assisted-by: <Model> via <Tool>
```

**Never use `castrojo` fork for bluefin/bluefin-lts/common/dakota.** Those forks are gone.

## projectbluefin/bluefin — Branch & Merge Rules

⚠️ **ALL PRs target `testing`. Never `main`.** The `main` branch exists but is NOT the development landing branch. Renovate, human PRs, CI fixes — everything goes to `testing`.

**Merge method:** squash only (`allow_squash_merge: true`, `allow_merge_commit: false`, `allow_rebase_merge: false`).

**No merge queue on `testing`** — direct `gh pr merge --squash` works. The merge queue (ruleset 17070404) only applies to `main`.

**pr-validation.yml** triggers on PRs to `testing`. If CI isn't running on a PR, check the branch filter.

**Renovate baseBranchPatterns** in `.github/renovate.json5` must be `["testing"]`. If Renovate PRs are landing on `main`, that field is wrong.

**Branch sync:** `main` and `testing` can diverge. When syncing:
```bash
git checkout testing && git merge projectbluefin/main --no-edit
# Resolve conflicts by taking main's versions (newer digests/pins)
git push projectbluefin testing
```

## How It Works
2. Build only when testing container changes (expensive: 30-90 min, 20-25GB disk)
3. When PR-ready: `gh pr create --repo projectbluefin/<repo>` (NOT open-pr.sh)

## Usage

```bash
# Validate (always run before committing)

# Manual build
just build bluefin latest main
just build bluefin-dx latest main
just clean
```

## Image Matrix

| Image | Tags | Flavors |
|---|---|---|
| `bluefin` | gts, stable, latest, beta | main, nvidia-open |
| `bluefin-dx` | gts, stable, latest, beta | main, nvidia-open |

## Output

validate.sh exits 0 on success, prints errors to stderr.

## Present Results to User

After `gh pr create`:
> "Branch `BRANCH` pushed to `projectbluefin/REPO`. PR #NNN opened. CI will run automatically."

## Troubleshooting

- `just check` fails on `.devcontainer.json` — expected, ignore it
- Build fails with disk space error — run `just clean` first
- `pre-commit` hook fails — run `just fix` then retry
- **GHA workflow `startup_failure` with zero jobs and no log output** — likely an org-only permission scope in the `permissions:` block. `artifact-metadata: write` is org-only and will cause silent `startup_failure` on any `castrojo/*` personal fork. **Do not bisect** — personal forks cannot validate org-only features. Instead: remove the scope from the fork copy, cite a working `ublue-os/aurora` workflow as proof, and submit upstream retaining the scope. *(observed: 2026-03-30, copilot-config issue 147)*

## Aurora is the Reference Implementation

When making any Justfile changes to bluefin, **check Aurora's Justfile first**:

```bash
curl -s https://raw.githubusercontent.com/ublue-os/aurora/main/Justfile | grep -A 20 "recipe-name"
```

Or fetch the full file: `https://raw.githubusercontent.com/ublue-os/aurora/main/Justfile`

**Rules:**
- Aurora and Bluefin share the same Justfile structure. Aurora changes (especially from maintainer renner0e) should be mirrored in Bluefin unless there is an explicit Bluefin-specific reason not to.
- When a reviewer links an Aurora PR as the reference, reproduce that PR's exact diff — do not produce a novel implementation.
- Bluefin-specific divergences (e.g. `silverblue-main` vs `kinoite`, `kernel_pin` usage) must be identified and documented, not silently dropped.
- Always fetch and read the Aurora version before writing any Justfile recipe.

## bluefin-common (projectbluefin/common) Key Patterns

**Repo:** `projectbluefin/common` | Agent-direct (no fork) | Local clone optional

> **Note on Dakota:** `projectbluefin/dakota` is a **CoreOS-model** bootc image (BuildStream 2, composefs, no rpm-ostree), not a variant of Bluefin. Changes to `common` do NOT flow into dakota. Dakota has its own BST elements. See `dakota-overview` skill.

**Just recipes** live in two places:
- `system_files/shared/usr/share/ublue-os/just/apps.just` — cross-distro app installs (hardware tools, IDE installs)
- `system_files/bluefin/usr/share/ublue-os/just/system.just` — Bluefin-specific system recipes

After editing any `.just` file: run `just fix` (auto-formats) then `just check` (validates). Both must pass clean before committing.

**Brewfiles** live in `system_files/shared/usr/share/ublue-os/homebrew/`. Key files:
- `ide.Brewfile` — IDE casks (vscode, vscodium, jetbrains, etc.)
- `system-flatpaks.Brewfile` — flatpaks preinstalled on all Bluefin
- `system-dx-flatpaks.Brewfile` — DX-only flatpaks
- `apps.just` sources from `ublue-os/tap` — always check the tap first

**Custom command menu** (`ujust`-launched panel menu) lives in **`projectbluefin/dakota`**, NOT in common:
- File: `files/dconf/05-dakota-custom-command-menu`
- Format: `commandN=('Label', 'command', 'icon', visible)` — type `(sssb)`
- Separator entries use `---Section Name` as the label with empty command
- Issue #284 (common) routes to dakota — always check dakota when issues reference the custom menu

**gschema overrides** for GNOME settings: `system_files/bluefin/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override`

**dconf distro keyfiles** (non-relocatable schemas, extension settings): `system_files/bluefin/etc/dconf/db/distro.d/`

**App folders** (GNOME grid): `system_files/bluefin/etc/dconf/db/distro.d/01-bluefin-folders`

**ASUS laptop support** (asusctl + ROG Control Center):
- Both casks in `ublue-os/tap` (main tap, not experimental): `asusctl-linux`, `rog-control-center-linux`
- Recipe: `ujust install-asus` in `apps.just`
- Requires: enable `asusd.service` (sudo) + `asusd-user.service` (user unit)

---

## common Testing on Ghost — Policy

**DO NOT** build a full bluefin image from RPMs to test common changes. common is pure file overlays (gschema, just scripts, dconf, env) — no RPMs come from it.

**Policy:** overlay common ctx onto `ghcr.io/ublue-os/bluefin:stable`, BIB to disk, swap titan.

Canonical script: `~/common-test-build.sh` on ghost (also at `/tmp/build-lab.sh`)

```bash
# Run on ghost — full pipeline ~3 min
bash ~/common-test-build.sh fix/my-branch
# Optional: specify base image
bash ~/common-test-build.sh fix/my-branch ghcr.io/ublue-os/bluefin:stable
```

**Pipeline steps:**
1. `git clone` common branch → `just build` → `localhost/bluefin-common:test`
2. `podman build` FROM bluefin:stable + COPY common layers + `glib-compile-schemas`
3. Push to `localhost:5000/bluefin-common-test:TAG`
4. `sudo podman pull` (rootless/rootful have separate stores)
5. `sudo podman run bootc-image-builder --type raw --rootfs btrfs` → disk.raw

**BIB notes (hard-won):**
- BIB must run as rootful (`sudo podman run`)
- `--rootfs btrfs` required — `bluefin:stable` lacks `/usr/lib/bootc/install/filesystem.json`
- SSH key field in config.toml is `key`, not `ssh_key`
- Push to zot first, then `sudo podman pull` — rootless and rootful have separate stores
- Output path must be absolute `/var/home/jorge/...` not `~/...` (sudo expands to `/root`)

**BIB config.toml:**
```toml
[[customizations.user]]
name = "jorge"
password = "bluefin"
key = "ssh-ed25519 AAAAC3..."
groups = ["wheel", "sudo"]
```

**After disk is built:**
```bash
# On ghost — swap titan disk and restart
kubectl delete vm titan-bluefin -n bluefin-test
cp ~/VMs/titans/titan-bluefin/image-new/image/disk.raw \
   ~/VMs/titans/titan-bluefin/image/disk.raw
kubectl apply -f ~/VMs/titans/titan-bluefin/vm.yaml
# SSH in via NodePort (key injected by BIB)
ssh -p 30223 jorge@192.168.1.102
```

**Titan SSH:** `ssh -o StrictHostKeyChecking=no -p 30223 jorge@192.168.1.102`
**titan-lts SSH:** `ssh -o StrictHostKeyChecking=no -p 30220 jorge@192.168.1.102`

---

## Brewfile Validation — Local Container Test

Before pushing any Brewfile change, validate it in a clean container that mirrors what CI does.

**CI workflow:** `.github/workflows/validate-brewfiles.yaml` — runs `brew info --formula/--cask NAME` after tapping dependencies. Triggers on changes to `system_files/shared/usr/share/ublue-os/homebrew/**`.

**Local equivalent (runs in ~60s):**

```bash
# Replace TAP and CASK_NAME with the actual values from the Brewfile entry
podman run --rm docker.io/homebrew/brew:latest bash -c "
  brew tap ublue-os/tap 2>&1 | tail -3 && \
  echo '--- checking cask ---' && \
  brew info --cask 'ublue-os/tap/CASK_NAME' 2>&1
"
```

For formulas:
```bash
podman run --rm docker.io/homebrew/brew:latest bash -c "
  brew tap ublue-os/tap 2>&1 | tail -3 && \
  brew info --formula 'FORMULA_NAME' 2>&1
"
```

For experimental-tap entries, swap `ublue-os/tap` → `ublue-os/experimental-tap`.

**Pass criteria:** `brew info` prints the cask/formula name, version, and artifact list without errors. Exit 0.

**Fail criteria:** `Error: No available formula or cask` — the name is wrong or the tap PR hasn't merged yet.

**Do not skip this step.** Brewfile PRs that reference unresolvable cask names will fail CI and waste a reviewer's time.

---

## projectbluefin/common — PR Review & Merge Queue

### Bulk PR testing workflow
Fetch all open PR branches as local worktrees, run `just check` on each:
```bash
cd ~/src/common
# Fetch all open PR refs
gh pr list --repo projectbluefin/common --state open --json number --jq '.[].number' | \
  xargs -I{} git fetch upstream refs/pull/{}/head:pr/{} -q

# Test each in a worktree
for PR in <list>; do
  WT="/tmp/pr-tests/pr${PR}"
  git worktree add "$WT" "pr/${PR}" -q
  OUTPUT=$(cd "$WT" && just check 2>&1); EXIT=$?
  [ $EXIT -eq 0 ] && echo "PR #${PR}: ✅ PASS" || echo "PR #${PR}: ❌ FAIL — $OUTPUT"
  git worktree remove "$WT" --force -q
  git branch -D pr/${PR} -q
done
rm -rf /tmp/pr-tests
```

### Merge queue ruleset (as of 2026-05-30)
- **Ruleset ID:** 11099358 — enforced, target: `main`
- **Required approvals:** 2 from different reviewers with write access
- **Merge method:** MERGE (not squash)
- **Queue config:** ALLGREEN, max 5 entries, min 1, 5-min wait, 60-min timeout
- **Enqueue via GraphQL:**
  ```bash
  NODE_ID=$(gh pr view $PR --repo projectbluefin/common --json id --jq .id)
  gh api graphql -f query="mutation { enqueuePullRequest(input: { pullRequestId: \"${NODE_ID}\" }) { mergeQueueEntry { id position } } }"
  ```
- **Blocker:** Can't self-approve own PRs. Castrojo-authored PRs (#346, #347, #356 etc.) need 2 external approvals.
- **Duplicate approvals don't count:** `gh pr view --json reviews` counts re-approvals from the same person as separate entries. Check unique approvers: `jq '[.reviews[] | select(.state=="APPROVED") | .author.login] | unique | length'`
- **New required checks block enqueue:** PRs opened before a required status check was added won't have that check in their history — the enqueue mutation fails with "N of N required status checks are expected." Fix: update the branch (`gh pr update-branch`) to trigger fresh CI. Check `maintainerCanModify` first — if false, comment asking the author to rebase.
- **`gh pr update-branch` requires `maintainerCanModify: true`** — check with `gh pr view $PR --json maintainerCanModify --jq .maintainerCanModify` before attempting.

### Key file paths (conflict resolution)
- `system_files/bluefin/etc/bazaar/hooks.py` — brew path is `/var/home/linuxbrew/.linuxbrew/bin/brew` (NOT `/home/linuxbrew`)
- `system_files/bluefin/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override` — frequently conflicts; `favorite-apps` and `enabled-extensions` are separate lines in the same block

---

## PR Hard Rule

> Never open upstream PRs or run `gh pr create`. See: workflow skill (Upstream PR Safety section).

## Flutter App Development (Bluefin Control Center)

### Stack decision (2026-05-29)
- **libadwaita ^2.0.2** — the only viable Flutter Adwaita widget library (gtk-flutter/libadwaita)
- **libadwaita_core ^0.5.4** — must be added explicitly; AdwActions/AdwControls live here, NOT re-exported by libadwaita
- **adwaita package** — BROKEN on Flutter stable. Uses deprecated `TabBarTheme` (not `TabBarThemeData`). Do not use.
- **adwaita_icons** — INCOMPATIBLE with libadwaita ^2.0. flutter_svg version conflict. Do not use.
- **yaru ^10.1.0** — conflicts with libadwaita (animated_vector → image dep conflict). Use one or the other, not both.

### GTK4 Flutter embedder
- Branch: `richyo-codes/flutter:issue-94804-gtk4-linux-may-rebase-v2` (PR flutter/flutter#186594)
- Build: `use_gtk4=true` GN flag + depot_tools + gclient sync
- GTK4 is windowing/compositor only — Skia still renders all widgets
- Stable timeline: 2027–2028. One community contributor. Zero Flutter team reviews yet.
- Castrojo tracking issue: castrojo/copilot-config#378

### GNOME 50 / libadwaita 1.9 key widgets for control center
- `AdwSidebar` + `AdwSidebarSection` + `AdwSidebarItem` (new in 1.9) — primary nav pattern
- `AdwNavigationSplitView` + `AdwBreakpoint` — adaptive two-pane layout
- `AdwToolbarView` — page scaffold with header/footer bars
- `AdwBottomSheet` (1.6), `AdwToggleGroup` (1.7), `AdwShortcutsDialog` (1.8)
- No libadwaita 2.0 announced. No GTK5 roadmap.

### Visual fidelity fix needed (tracked: castrojo/copilot-config#379)
Adwaita palette hex values:
- Blue: `#3584E4`, Red: `#E01B24`
- Window bg: `#FAFAFA` (light) / `#1E1E1E` (dark)
- Card bg: `#FFFFFF` (light) / `#2B2B2B` (dark)
- Header bg: `#EBEBEB` (light) / `#303030` (dark)
- Border: `rgba(0,0,0,0.12)` (light) / `#454545` (dark)
