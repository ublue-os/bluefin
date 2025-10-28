# Quick Start: Generate GTS F41→F42 Changelog Issue

This is a quick reference for generating the changelog issue for the GTS build transition from Fedora 41 to Fedora 42.

## Current Use Case

Generate a changelog between:
- **Previous**: `gts-41.20251024` (Fedora 41, October 24, 2025)
- **Current**: `gts-42.20251028` (Fedora 42, October 28, 2025)

## Option 1: Run via GitHub Actions UI (Recommended)

1. Navigate to: https://github.com/ublue-os/bluefin/actions/workflows/generate-gts-changelog-issue.yml
2. Click "Run workflow"
3. Fill in the inputs:
   - **prev_tag**: `gts-41.20251024`
   - **curr_tag**: `gts-42.20251028`
4. Click "Run workflow"

The workflow will automatically create a GitHub issue with the complete changelog.

## Option 2: Run Locally

```bash
# Set your GitHub token
export GITHUB_TOKEN=your_github_token_here

# Run the script
python3 .github/generate_gts_changelog_issue.py \
  gts-41.20251024 \
  gts-42.20251028 \
  --workdir . \
  --repo ublue-os/bluefin
```

## What You'll Get

The generated issue will include:

- **Title**: "GTS Changelog: gts-41.20251024 → gts-42.20251028"
- **Major package versions**: Kernel, GNOME, Mesa, Podman, NVIDIA
- **Dev Experience packages**: Incus, Docker
- **Complete package diff**: All added/changed/removed packages
- **Commit history**: Git commits between the two builds
- **Rebase instructions**: How users can upgrade

## Labels Applied

The issue will be automatically tagged with:
- `changelog`
- `gts`
- `automated`

## Expected Output

The changelog will show the Fedora version transition (41→42) and list hundreds of package updates, similar to release changelogs but formatted as an issue instead of a release note.
