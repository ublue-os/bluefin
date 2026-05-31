# Bluefin Release Skill

Manages releases, changelogs, and stream tag progression.

## When to Use

- Cutting a new release for any Bluefin stream (gts/stable/latest/beta)
- Generating changelogs with `just changelogs BRANCH`
- Managing stream tag progression (understanding what moves when)
- Writing or editing GitHub release notes

## When NOT to Use

- Day-to-day code changes that are not a release — use [docs/skills/build.md](docs/skills/build.md)
- Handling Renovate version bump PRs — use [docs/skills/renovate.md](docs/skills/renovate.md)
- ISO promotion as part of a release — also load [docs/skills/iso.md](docs/skills/iso.md)

## How It Works

1. Identify the target stream (gts/stable/latest/beta)
2. Generate changelog: `bash /mnt/skills/user/bluefin-release/scripts/changelog.sh BRANCH`
3. Review and edit changelog
4. Tag and push via GitHub Actions

## Stream Cadence

| Stream | Base | Stability | Notes |
|---|---|---|---|
| `gts` | F42 | Highest | Good Till September — long support |
| `stable` | F42 | High | Current stable Fedora |
| `latest` | F42/43 | Medium | Tracks latest Fedora |
| `beta` | F42/43 | Low | Testing upcoming changes |

## Usage

```bash
# Generate changelog for a stream

# Or via just directly
just changelogs stable
just changelogs stable "optional handwritten notes"
```

**Arguments:**
- `branch` — stream name: `stable`, `gts`, `latest`, `beta`
- `handwritten` — optional additional notes to prepend

## Output

Changelog in markdown format, ready for GitHub release notes.

## Release Checklist

1. [ ] CI passing on target branch
2. [ ] `just changelogs BRANCH` reviewed and edited
3. [ ] Tag created via GitHub Actions (not manual)
4. [ ] Release notes published
5. [ ] Announcement in appropriate channels

## Learnings

<!-- Background agents append here automatically -->
