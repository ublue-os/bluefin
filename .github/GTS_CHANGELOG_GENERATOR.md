# GTS Changelog Generator for GitHub Issues

This tool generates detailed changelogs between two GTS (Grand Touring Support) builds and posts them as GitHub issues. It's particularly useful for tracking Fedora version transitions (e.g., F41 to F42).

## Features

- Generates comprehensive package version comparisons
- Tracks added, changed, and removed packages
- Separates packages by category (All Images, Dev Experience, Nvidia)
- Includes commit history between builds
- Preserves markdown formatting for easy reading
- Automatically posts as a GitHub issue with labels

## Usage

### Manual Run

You can run the script manually to generate a changelog:

```bash
# Set your GitHub token
export GITHUB_TOKEN=your_token_here

# Generate changelog between two GTS tags
python3 .github/generate_gts_changelog_issue.py \
  gts-41.20251024 \
  gts-42.20251028 \
  --workdir . \
  --repo ublue-os/bluefin
```

### Via GitHub Actions Workflow

The workflow can be triggered manually from the GitHub Actions UI:

1. Go to Actions → "Generate GTS Changelog Issue"
2. Click "Run workflow"
3. Enter the previous tag (e.g., `gts-41.20251024`)
4. Enter the current tag (e.g., `gts-42.20251028`)
5. Click "Run workflow"

The workflow will:
- Fetch manifests for both tags from GHCR
- Compare package versions
- Generate the changelog
- Create a GitHub issue with the changelog

### Workflow Integration (Optional)

To automatically trigger changelog generation after GTS builds, you can add this to your build workflow:

```yaml
jobs:
  build-gts:
    # ... your build configuration ...

  generate-changelog-issue:
    name: Generate GTS Changelog Issue
    needs: [build-gts]
    if: github.event_name == 'schedule' # Or your trigger condition
    uses: ./.github/workflows/generate-gts-changelog-issue.yml
    with:
      prev_tag: gts-41.20251024  # Dynamic value needed
      curr_tag: gts-42.20251028  # Dynamic value needed
```

## Output Format

The generated changelog includes:

1. **Title**: Shows the tag transition (e.g., "GTS Changelog: gts-41.20251024 → gts-42.20251028")
2. **Major Packages**: Kernel, GNOME, Mesa, Podman, NVIDIA versions
3. **Major DX Packages**: Incus, Docker versions
4. **Commit History**: Git commits between the two builds
5. **All Images**: Common package changes across all variants
6. **Dev Experience Images**: DX-specific package changes
7. **Nvidia Images**: Nvidia-specific package changes
8. **Rebase Instructions**: How users can switch to the new version

## Package Version Format

- 🔄 Changed: `package-name | old-version | new-version`
- ✨ Added: `package-name | | new-version`
- ❌ Removed: `package-name | old-version | `

## Labels

Issues are automatically tagged with:
- `changelog`
- `gts`
- `automated`

## Requirements

- Python 3.x
- `skopeo` (for fetching container manifests)
- `requests` library
- GitHub token with `issues: write` permission
- Git repository for commit history

## Tag Format

GTS tags should follow the format: `gts-<fedora_version>.<date>`

Examples:
- `gts-41.20251024` (Fedora 41, October 24, 2025)
- `gts-42.20251028` (Fedora 42, October 28, 2025)

The script automatically extracts the Fedora version from the tag name.
