# Bluefin — Agent & Copilot Instructions

**Bluefin** is a cloud-native desktop OS built on Fedora Linux using container technologies with atomic updates. Home repo: [projectbluefin/bluefin](https://github.com/projectbluefin/bluefin).

## Load the right skill first

Skills live in this repo under [`docs/skills/`](docs/skills/README.md).
Read the matching file before making any changes.

| Task | Skill file |
|------|------------|
| Build, validate, or submit a PR | [docs/skills/build.md](docs/skills/build.md) |
| Debug a CI failure | [docs/skills/ci.md](docs/skills/ci.md) |
| Add, remove, or update a package | [docs/skills/packages.md](docs/skills/packages.md) |
| Cut a release or manage stream tags | [docs/skills/release.md](docs/skills/release.md) |
| Review or merge a Renovate PR | [docs/skills/renovate.md](docs/skills/renovate.md) |
| COPR repos, cosign, or security decisions | [docs/skills/security.md](docs/skills/security.md) |
| Understand image variants and stream matrix | [docs/skills/variants.md](docs/skills/variants.md) |
| Work on the LTS image | [docs/skills/lts.md](docs/skills/lts.md) |
| Build or promote ISOs | [docs/skills/iso.md](docs/skills/iso.md) |

## Repo layout (quick reference)

```
Containerfile          # Multi-stage build: base → dx
Justfile               # Build automation (just build / just check / just fix)
build_files/
  base/                # Base image scripts (run in numerical order)
  dx/                  # Developer experience layer scripts
  shared/              # Shared helpers (copr-helpers.sh, build.sh, …)
system_files/          # Files copied verbatim into the image
flatpaks/              # Flatpak lists (base + dx)
brew/                  # Homebrew Brewfiles
just/                  # Extra just recipes
.github/workflows/     # CI/CD pipelines
```

## Non-negotiable rules

1. **Conventional commits** — every commit and PR title must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
2. **Stay surgical** — minimal, targeted changes only. This repo prioritises maintainability.
3. **Validate before committing** — run `just check && pre-commit run --all-files` (pre-commit is mandatory; `just check` requires Just installed).
4. **Never run full container builds locally** unless testing container changes — they take 30–90 min and need 25 GB+ disk.
5. **Attribution** — include the Assisted-by footer on every AI-authored commit:
   ```
   Assisted-by: <Model Name> via <Tool Name>
   ```
6. **Security** — COPR packages must use `copr_install_isolated()` from `build_files/shared/copr-helpers.sh`. Never mix COPR and Fedora package arrays (prevents repo injection attacks).

## Related projects

- Documentation: [projectbluefin/bluefin-docs](https://github.com/projectbluefin/bluefin-docs) / [docs.projectbluefin.io](https://docs.projectbluefin.io)
- LTS variant: [projectbluefin/bluefin-lts](https://github.com/projectbluefin/bluefin-lts)
- Common layer: [projectbluefin/common](https://github.com/projectbluefin/common)
