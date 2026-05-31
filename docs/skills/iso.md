# Bluefin ISO Build Skill

Manages the ISO build and promotion pipeline using Titanoboa and Anaconda.

## When to Use

- Building installation ISOs via variant workflows (`build-iso-stable.yml`,
  `build-iso-lts-hwe.yml`, and controlled `build-iso-lts.yml` testing)
- Promoting ISOs from testing to production in CloudFlare R2
- Troubleshooting the ISO build or promotion pipeline
- Generating torrents for production ISOs

## When NOT to Use

- Changing image contents or packages — use [docs/skills/build.md](docs/skills/build.md)
- **LTS ISOs — DISABLED. Never build or promote LTS ISOs (see critical warning below)**
- CI failures unrelated to ISO promotion — use [docs/skills/ci.md](docs/skills/ci.md)

## ⚠️ CRITICAL: LTS ISO Hard Stop

**LTS ISOs are BROKEN and DISABLED. Before any ISO operation:**
- DO NOT re-enable `build-iso-lts.yml` schedule
- DO NOT run `promote-iso.yml` with `variant: lts` unless `allow_unsafe_lts=true`
- DO NOT add `variant: all` back to `promote-iso.yml`
- DO NOT assume `build-iso-all.yml` is promotion-safe for non-HWE LTS
- Production LTS ISOs in R2 must NOT be overwritten

Run safety check first: `bash /mnt/skills/user/bluefin-iso/scripts/promote-iso.sh`

## How It Works

1. Container images built → pushed to `ghcr.io/ublue-os`
2. Variant workflows call reusable build logic using Titanoboa + Anaconda
3. ISOs uploaded to R2 testing bucket
4. Per-run torrent artifacts produce a prerelease
5. `promote-iso.yml` preflights and copies variant assets testing → production
6. Promotion creates a new production release tag derived from source prerelease

## Usage

```bash
# Safe ISO promotion (LTS-guarded)

# Generate changelog
just changelogs stable
```

**Arguments for promote-iso.sh:**
- `VARIANT` — use `stable` or `lts-hwe` for safe default paths.
- Non-HWE `lts` requires explicit unsafe override and operator intent.

## Output

promote-iso.sh prints status, enforces LTS safety rules, and blocks unsafe invocations.

## Troubleshooting

- Build fails: check `ghcr.io/ublue-os` image exists for the target tag/flavor
- Anaconda errors: known issue with LTS base — do not attempt to fix without deep investigation
- R2 access: requires CloudFlare credentials in GitHub secrets

## Learnings

### ublue-flatpak-manager.service removed from image (2026-05-11)

`ublue-flatpak-manager.service` no longer exists in the Bluefin image or anywhere
in the ublue-os ecosystem (`ublue-os/packages`, `ublue-os/main`,
`projectbluefin/common` — all checked). `systemctl --global disable` exits
non-zero on a missing unit, aborting `hook-post-rootfs` under `set -eoux pipefail`.

Fix: remove the disable line from both hook scripts (not just comment out).
Applied in projectbluefin/iso PR #53.

**Bazzite pattern worth adopting:** Bazzite guards all service disable calls
with `if systemctl list-unit-files "$s" >/dev/null 2>&1; then systemctl disable
"$s"; fi` — makes the script resilient to upstream service removal without
breaking the build.

**GDX ISOs:** `build-iso-lts.yml` has `workflow_dispatch` disabled at the repo
level. GDX ISOs can only be triggered via the monthly cron — not manually.

### arm64 ISO builds: Exec format error (2026-04-01)

arm64 ISO builds (lts and lts-hwe variants) are currently failing with:

```
{"msg":"exec container process `/usr/bin/bash`: Exec format error","level":"error"}
error: Recipe `initramfs` failed with exit code 1
```

Root cause: Titanoboa's initramfs step runs a CentOS container (`builder-distro: centos`) on the `ubuntu-24.04-arm` runner. The arm runner cannot exec the container's bash — an upstream Titanoboa or GitHub arm runner issue with CentOS-based containers. Not caused by the ISO workflow config.

**Impact before fix:** `create-prerelease` job was gated on all build matrix jobs succeeding. arm64 failures caused the prerelease to be skipped entirely for LTS and LTS-HWE variant runs. Stable was unaffected (no arm64 in stable matrix).

**Mitigation shipped (projectbluefin/iso PR pending):** Changed `create-prerelease` job condition to `needs.build.result != 'cancelled'` so the prerelease publishes with whatever amd64 ISOs succeeded. Release notes now include a per-platform build status table.

**Pre-existing state check:** Before diagnosing a "blocked release", check `gh release list --repo projectbluefin/iso` — `build-iso-all.yml` runs multiple reusable workflow invocations, and the stable invocation's prerelease job may have already published a release even if LTS/LTS-HWE prerelease jobs were skipped.

### dakota-iso: VFS layer explosion and squash fix (2026-05-01)

`projectbluefin/dakota-iso` uses `podman` to import OCI images into a VFS
containers-storage dir that gets embedded in the ISO squashfs. With chunkified
images (~120 layers), VFS imports each layer as a full directory tree → ~6GB × 120
= ~720GB peak disk usage, overflowing any standard CI runner.

**Fix:** squash to 1 layer BEFORE the VFS import using `buildah`:

```bash
buildah from --pull-never "${IMAGE}"
# ... (get container ID) ...
buildah commit --squash "${CTR}" "localhost/${target}-squashed:build"
buildah rm "${CTR}"
```

**Critical:** Do NOT use `podman create --entrypoint /bin/sh && podman commit --squash`.
`podman create --entrypoint` records `/bin/sh` in the container config; `podman commit`
captures that modified config. bootc images have no Entrypoint by design — the fake
`/bin/sh` entrypoint causes `bootc install` to fail with "cannot execute binary file".
`buildah from/commit --squash` preserves the original image config.

### dakota-iso: live-ready.service and serial console (2026-05-01)

The live ISO boots a QEMU VM headlessly (`-display none -serial file:/tmp/serial.log`).
CI polls the serial log for a `DAKOTA_LIVE_READY` marker to confirm GDM is up.

**WantedBy:** Use `WantedBy=multi-user.target` (NOT `WantedBy=display-manager.service`).
The latter is non-standard and causes the service to silently not run on some installer
channels. Use `After=display-manager.service` for ordering only.

**StandardOutput:** Use `StandardOutput=tty` + `TTYPath=/dev/ttyS0` to write the marker
directly to the serial device. `StandardOutput=journal+console` routes to `/dev/console`
which is NOT the serial device in headless QEMU — the systemd `[OK] Finished …` message
appears (from the kernel console driver) but the `ExecStart=` output does not.

**Boot verification grep:** Accept either `DAKOTA_LIVE_READY` (explicit serial write)
OR `Finished live-ready.service` (systemd status message, always on serial) as fallback:
```bash
grep -qE "DAKOTA_LIVE_READY|Finished live-ready\.service" /tmp/serial.log
```

**LUKS test readiness:** The justfile's `luks-boot-qemu-live` recipe also checks SSH
connectivity as a fallback when the serial marker is absent (e.g. dev installer channel).

### dakota-iso: composefs disk check (2026-05-01)

`df /` reports 0 bytes free on composefs/ostree hosts — the read-only root mount has no
free space from df's perspective. Always target `${OUTPUT_DIR}` (a real writable path)
for disk space checks, not `/`.

<!-- Background agents append here automatically -->
