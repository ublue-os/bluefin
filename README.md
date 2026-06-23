# bluefin

Custom [Bluefin](https://projectbluefin.io/) images with NVIDIA 580 proprietary drivers and Epson printer support, built for personal use on Maxwell/Pascal/Volta hardware.

## Images

All images are published at `ghcr.io/lbssousa/` and rebuilt daily.

| Image | Base | Additions |
|---|---|---|
| `bluefin` | `ublue-os/bluefin:stable` | Epson, FIDO2/U2F |
| `bluefin-dx` | `ublue-os/bluefin-dx:stable` | Epson, FIDO2/U2F |
| `bluefin-nvidia` | `ublue-os/bluefin:stable` | NVIDIA 580 + Epson, FIDO2/U2F |
| `bluefin-dx-nvidia` | `ublue-os/bluefin-dx:stable` | NVIDIA 580 + Epson, FIDO2/U2F |
| `bluefin-nvidia-open` | `ublue-os/bluefin-nvidia-open:stable` | Epson, FIDO2/U2F |
| `bluefin-dx-nvidia-open` | `ublue-os/bluefin-dx-nvidia-open:stable` | Epson, FIDO2/U2F |

## About the NVIDIA 580 driver

Driver branch 580 is the last to support **Maxwell, Pascal, and Volta** GPUs (GeForce 700–10xx series and Titan V). Starting from branch 590, NVIDIA dropped support for these architectures.

The `bluefin-nvidia` and `bluefin-dx-nvidia` images use the proprietary 580 driver sourced from the [negativo17 `fedora-nvidia-lts` repository](https://negativo17.org/nvidia-driver-580-lts-repository/), maintained until ~June 2028.

The `bluefin-nvidia-open` and `bluefin-dx-nvidia-open` images inherit the NVIDIA open drivers directly from the official Bluefin upstream images (Turing+ GPUs only).

## Installation

Switch to the image matching your hardware:

```bash
# NVIDIA proprietary (Maxwell/Pascal/Volta — GeForce 700-10xx)
sudo bootc switch ghcr.io/lbssousa/bluefin-nvidia:stable

# NVIDIA open (Turing+ — GeForce 16xx/20xx/30xx/40xx/50xx)
sudo bootc switch ghcr.io/lbssousa/bluefin-nvidia-open:stable

# No NVIDIA GPU
sudo bootc switch ghcr.io/lbssousa/bluefin:stable
```

### SecureBoot (NVIDIA proprietary only)

After first boot, enroll the MOK key to allow the signed NVIDIA module to load:

```bash
sudo mokutil --import /etc/pki/akmods/certs/akmods-ublue.der
# enter a temporary password, then confirm it in the MOK Manager on next reboot
```

### FIDO2/U2F authentication

All images include `pam-u2f`, enabling hardware security key authentication for login and sudo. The upstream Bluefin image ships `libfido2` (udev rules for device access) but omits the PAM module, so `authselect`'s `with-pam-u2f` feature would reference a missing `pam_u2f.so`.

To enable it after installation, if not already configured:

```bash
authselect enable-feature with-pam-u2f
```

## How it works

### Image architecture

Each image is a thin layer on top of the official Bluefin upstream image — no packages are reinstalled, no base is rebuilt from scratch. This keeps the diff minimal and the sync with upstream automatic.

```
ghcr.io/ublue-os/bluefin:stable          ← official Bluefin (unchanged)
  └─ signing policy (ghcr.io/lbssousa)   ← 00-signing.sh
  └─ Epson printer driver + utility      ← 20-epson.sh
  └─ pam-u2f (FIDO2/U2F PAM module)     ← 30-u2f.sh
```

For the NVIDIA proprietary variants, pre-built kernel modules from `ghcr.io/ublue-os/akmods-nvidia-lts` are installed on top of the Bluefin base. The CI derives the exact kernel version from the pinned base image at build time and selects the corresponding `main-44-<kernel>` akmod tag — ensuring the kernel module always matches the running kernel.

### Staying in sync

- **Upstream Bluefin**: Renovate bumps the base image digests in `image-versions.yml` automatically. Digest updates for all six base images auto-merge.
- **NVIDIA kernel modules**: When the base image digest changes to a new kernel, CI automatically derives the new kernel version and fetches the matching `akmods-nvidia-lts` tag. No manual action needed.
- **Epson packages**: A weekly workflow checks the Epson Download Center API and the AUR for new versions. If both a new version and download URL are found, a PR is opened automatically.

## Verification

Images are signed with [cosign](https://github.com/sigstore/cosign). The public key is committed at `cosign.pub` in this repository. The signing policy is embedded in the image itself under `/etc/containers/policy.json`, so `bootc upgrade` verifies signatures automatically.

To verify manually:

```bash
cosign verify --key cosign.pub ghcr.io/lbssousa/bluefin:stable
```
