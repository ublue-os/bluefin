# Bluefin Copilot Instructions

This document provides essential information for coding agents working with the Bluefin repository to minimize exploration time and avoid common build failures.

## Repository Overview

**Bluefin** is a cloud-native desktop operating system that reimagines the Linux desktop experience. It's an OS built on Fedora Linux using container technologies with atomic updates.

- **Type**: Container-based Linux distribution build system (75MB total, 74MB system files)
- **Base**: Fedora Linux with GNOME Desktop + Universal Blue infrastructure
- **Languages**: Bash scripts, JSON configuration, Python utilities
- **Build System**: Just (command runner), Podman/Docker containers, GitHub Actions
- **Target**: desktop OS with two variants (base + developer experience)

## Repository Structure

### Root Directory Files
- `Containerfile` - Main container build definition (multi-stage: base → dx)
- `Justfile` - Build automation recipes (33KB - like Makefile but more readable)
- `.pre-commit-config.yaml` - Pre-commit hooks for basic validation
- `image-versions.yml` - Image version configurations
- `cosign.pub` - Container signing public key

### Key Directories
- `system_files/` (74MB) - User-space files, configurations, fonts, themes
- `build_files/` - Build scripts organized as base/, dx/, shared/
  - `base/` - Base image build scripts (00-image-info.sh through 19-initramfs.sh)
  - `dx/` - Developer experience build scripts
  - `shared/` - Common build utilities and helper scripts
- `.github/workflows/` - Comprehensive CI/CD pipelines
- `just/` - Additional Just recipes for apps and system management
- `brew/` - Homebrew Brewfile definitions for various tool collections
- `flatpaks/` - Flatpak application lists (system-flatpaks.list, system-flatpaks-dx.list)

### Architecture
- **Two Build Targets**: `base` (regular users) and `dx` (developer experience)
- **Image Flavors**: main, nvidia-open
- **Fedora Versions**: 42, 43 supported
- **Stream Tags**: `latest` (F42/43), `beta` (F42/43), `stable` (F42), `gts` (F42 Grand Touring Support)
- **Build Process**: Sequential shell scripts in build_files/ directory
- **Base Images**: Uses `ghcr.io/ublue-os/silverblue-main` as foundation from Universal Blue

## Build Instructions

### Prerequisites
**ALWAYS install these tools before attempting any builds:**

```bash
# Install Just command runner (REQUIRED for build commands, may not be available)
# If external access is limited, Just commands will not work
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Verify container runtime (usually available)
podman --version || docker --version

# Install pre-commit for validation (usually works)
pip install pre-commit
```

**Note**: In restricted environments, Just command runner may not be installable. Most validation can still be done with pre-commit and manual JSON validation.

### Essential Commands

**Build validation (ALWAYS run before making changes):**
```bash
# 1. Validate syntax and formatting (2-3 minutes)
# Note: .devcontainer.json will fail JSON check due to comments - this is expected
pre-commit run --all-files

# 2. Check Just syntax (requires Just installation)
just check  # Only if Just command runner is available

# 3. Fix formatting issues automatically
just fix    # Only if Just command runner is available
```

**Build commands (use with extreme caution - these take 30+ minutes and require significant resources):**
```bash
# Build base image (30-60 minutes, requires 20GB+ disk space)
just build bluefin latest main

# Build developer variant (45-90 minutes, requires 25GB+ disk space)
just build bluefin-dx latest main

# Build with specific kernel pin
just build bluefin latest main "" "" "" "6.10.10-200.fc40.x86_64"
```

**Utility commands:**
```bash
# Clean build artifacts (if Just available)
just clean

# List all available recipes (if Just available)
just --list

# Validate image/tag/flavor combinations (if Just available)
just validate bluefin latest main
```

**Working without Just (when external access is restricted):**
```bash
# Manual validation instead of 'just check':
find . -name "*.just" -exec echo "Checking {}" \; -exec head -5 {} \;

# Manual cleanup instead of 'just clean':
rm -rf *_build* previous.manifest.json changelog.md output.env

# View Justfile recipes manually:
grep -n "^[a-zA-Z].*:" Justfile | head -20
```

### Critical Build Notes

1. **Container builds require massive resources** (20GB+ disk, 8GB+ RAM, 30+ minute runtime)
2. **Always run `just check` before making changes** - catches syntax errors early
3. **Pre-commit hooks are mandatory** - run `pre-commit run --all-files` to validate changes
4. **Never run full builds in CI unless specifically testing container changes**
5. **Use `just clean` to reset build state if encountering issues**

### Common Build Failures & Workarounds

**Pre-commit failures:**
```bash
# Known issue: .devcontainer.json contains comments (invalid for JSON checker)
# This failure is expected and can be ignored:
# ".devcontainer.json: Failed to json decode"

# Fix end-of-file and trailing whitespace automatically
pre-commit run --all-files
```

**Just syntax errors (if Just is available):**
```bash
# Auto-fix formatting
just fix

# Manual validation
just check
```

**Container build failures:**
- Ensure adequate disk space (25GB+ free)
- Clean previous builds: `just clean` (if available)
- Check container runtime: `podman system info` or `docker system info`
- Build failures often indicate resource constraints rather than code issues

## Validation Pipeline

### Pre-commit Hooks (REQUIRED)
The repository uses mandatory pre-commit validation:
- `check-json` - Validates JSON syntax
- `check-toml` - Validates TOML syntax
- `check-yaml` - Validates YAML syntax
- `end-of-file-fixer` - Ensures files end with newline
- `trailing-whitespace` - Removes trailing whitespace

**Always run:** `pre-commit run --all-files` before committing changes.

### GitHub Actions Workflows
- `build-image-latest-main.yml` - Builds latest images on main branch changes
- `build-image-stable.yml` - Builds stable release images
- `build-image-gts.yml` - Builds GTS (Grand Touring Support) images
- `build-image-beta.yml` - Builds beta images for testing F42/F43
- `reusable-build.yml` - Core build logic for all image variants
- `generate-release.yml` - Generates release artifacts and changelogs
- `validate-brewfiles.yml` - Validates Homebrew Brewfile syntax
- `clean.yml` - Cleanup old images and artifacts
- `moderator.yml` - Repository moderation tasks

**Workflow Architecture:**
- Stream-specific workflows (gts, stable, latest, beta) call `reusable-build.yml`
- `reusable-build.yml` builds both base and dx variants for all flavors (main, nvidia-open)
- Fedora version is dynamically detected based on stream tag
- Images are signed with cosign and pushed to GHCR

### Manual Validation Steps
1. `pre-commit run --all-files` - Runs validation hooks (2-3 minutes, .devcontainer.json failure is expected)
2. `just check` - Validates Just syntax (if Just is available, 30 seconds)
3. `just fix` - Auto-fixes formatting issues (if Just is available, 30 seconds)
4. Test builds only if making container-related changes (30+ minutes)

## Package Management

### Package Configuration
Packages are defined directly in build scripts rather than in a central configuration file:
- `build_files/base/04-packages.sh` - Core package installations
  - `FEDORA_PACKAGES` array - Packages from official Fedora repos (installed in bulk)
  - `COPR_PACKAGES` array - Packages from COPR repos (installed individually with isolated enablement)
  - Fedora version-specific package sections using case statements (e.g., `42)`, `43)`)
- `build_files/dx/00-dx.sh` - Developer experience package additions

### COPR Package Installation

COPR packages use the `copr_install_isolated()` helper function from `build_files/shared/copr-helpers.sh`:
```bash
# Install packages from COPR with isolated repo enablement
copr_install_isolated "ublue-os/staging" package1 package2

```

This function:
1. Enables the COPR repo
2. Immediately disables it
3. Installs packages with `--enablerepo` flag to prevent repo conflicts

### Making Package Changes
1. Edit the appropriate shell script in `build_files/base/` or `build_files/dx/`
2. Add packages to the appropriate array (`FEDORA_PACKAGES` or `COPR_PACKAGES`)
3. For version-specific packages, add them in the Fedora version case statement
4. Validate shell script syntax: `bash -n build_files/base/04-packages.sh`
5. Run pre-commit hooks: `pre-commit run --all-files`
6. Test with container build if making critical changes

### Package Security Model
**CRITICAL**: Packages are split into separate arrays to prevent COPR repos from injecting malicious versions of Fedora packages:
- Fedora packages are installed first in bulk (safe)
- COPR packages are installed individually with isolated repo enablement

## Configuration Files

### Key Configuration Locations
- `system_files/shared/` - System-wide configurations
- `build_files/base/` - Base image build scripts
- `build_files/dx/` - Developer experience build scripts
- `build_files/shared/` - Common build utilities
- `.github/workflows/` - CI/CD pipeline definitions

### Linting/Build Configurations
- `.pre-commit-config.yaml` - Pre-commit hook configuration
- `Justfile` - Build recipe definitions and validation
- `.github/renovate.json5` - Automated dependency updates
- `Containerfile` - Container build instructions

## Build System Deep Dive

### Justfile Structure
The `Justfile` is the central build orchestration tool with these key recipes:

**Validation Recipes:**
- `just check` - Validates Just syntax across all .just files
- `just fix` - Auto-formats Just files
- `just validate <image> <tag> <flavor>` - Validates image/tag/flavor combinations

**Build Recipes:**
- `just build <image> <tag> <flavor>` - Main build command (calls build.sh)
- `just build-ghcr <image> <tag> <flavor>` - Build for GHCR (GitHub Container Registry)
- `just rechunk <image> <tag> <flavor>` - Rechunk image for optimization

**Image/Tag Definitions:**
```bash
images: bluefin, bluefin-dx
flavors: main, nvidia-open
tags: gts, stable, latest, beta
```

**Version Detection:**
- `just fedora_version <image> <tag> <flavor>` - Dynamically detects Fedora version from upstream base images
- For `gts` and `stable`: Checks `ghcr.io/ublue-os/base-main:<tag>`
- For `latest`/`beta`: Checks corresponding upstream tags
- Returns the Fedora major version (e.g., 42, 43)

### Containerfile Multi-Stage Build
The `Containerfile` uses a multi-stage build process:

1. **Stage `ctx`** (FROM scratch): Copies all build context (system_files, build_files, etc.)
2. **Stage `base`** (FROM silverblue-main): Base Bluefin image
   - Mounts build context from `ctx` stage
   - Runs `/ctx/build_files/shared/build.sh` which executes all scripts in order
3. **Stage `dx`** (optional, in full Containerfile): Developer experience layer

**Build Arguments:**
- `BASE_IMAGE_NAME` - Upstream base (silverblue/kinoite)
- `FEDORA_MAJOR_VERSION` - Dynamically set by Just (42/43)
- `IMAGE_NAME` - Target image name (bluefin/bluefin-dx)
- `KERNEL` - Pinned kernel version (optional)
- `UBLUE_IMAGE_TAG` - Stream tag (gts/stable/latest/beta)

### Build Script Execution Order
Scripts in `build_files/base/` execute in numerical order:
1. `00-image-info.sh` - Sets image metadata and os-release info
2. `03-install-kernel-akmods.sh` - Installs kernel and akmod packages
3. `04-packages.sh` - Installs Fedora and COPR packages
4. `05-override-install.sh` - Overrides base image packages
5. `08-firmware.sh` - Firmware configurations
6. `17-cleanup.sh` - Cleanup operations
7. `18-workarounds.sh` - Temporary fixes/workarounds
8. `19-initramfs.sh` - Regenerates initramfs

### Additional Recipe Collections
- `just/bluefin-apps.just` - User-facing app management recipes
- `just/bluefin-system.just` - System management recipes
- `brew/*.Brewfile` - Homebrew package collections (ai, cli, fonts, k8s)

## Development Guidelines

### Making Changes
1. **ALWAYS validate first:** `just check && pre-commit run --all-files`
2. **Make minimal modifications** - prefer configuration over code changes
3. **Test formatting:** `just fix` to auto-format
4. **Avoid full container builds** unless specifically testing container changes
5. **Focus on system_files/ changes** for most user-facing modifications

### File Editing Best Practices
- **JSON files**: Validate syntax with `pre-commit run check-json`
- **YAML files**: Validate syntax with `pre-commit run check-yaml`
- **Justfile**: Always run `just check` after modifications
- **Shell scripts**: Follow existing patterns in build_files/

### Common Modification Patterns
- **Adding packages**: Edit `build_files/base/04-packages.sh`, add to appropriate array
- **System configuration**: Modify files in `system_files/shared/`
- **Build logic**: Edit scripts in `build_files/base/` or `build_files/dx/`
- **CI/CD**: Modify workflows in `.github/workflows/`

## Trust These Instructions

**The information in this document has been validated against the current repository state.** Only search for additional information if:
- Instructions are incomplete for your specific task
- You encounter errors not covered in the workarounds section
- Repository structure has changed significantly

This repository is complex but well-structured. Following these instructions will significantly reduce build failures and exploration time.

## Other Rules that are Important to the Maintainers

- Ensure that [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) are used and enforced for every commit and pull request title.
- Always be surgical with the least amount of code, the project strives to be easy to maintain.
- Documentation for this project exists in ublue-os/bluefin-docs
- Bluefin LTS exists in ublue-os/bluefin-lts

## Attribution Requirements

AI agents must disclose what tool and model they are using in the "Assisted-by" commit footer:

```text
Assisted-by: [Model Name] via [Tool Name]
```

Example:

```text
Assisted-by: Claude 3.5 Sonnet via GitHub Copilot
```
