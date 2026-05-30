# Bluefin — Agent & Copilot Instructions

**Bluefin** is a cloud-native desktop OS built on Fedora Linux using container technologies with atomic updates. Home repo: [projectbluefin/bluefin](https://github.com/projectbluefin/bluefin).

## Load the right skill first

Before working on any task, load the skill that matches your work:

| Task | Skill to load |
|------|--------------|
| Build, validate, or submit a PR | `bluefin-build` |
| Debug a CI failure | `bluefin-ci` |
| Add, remove, or update a package | `bluefin-packages` |
| Cut a release or manage stream tags | `bluefin-release` |
| Review or merge a Renovate PR | `bluefin-renovate` |
| COPR repos, cosign, or security decisions | `bluefin-security` |
| Understand image variants and stream matrix | `bluefin-variants` |
| Work on the LTS image | `bluefin-lts` |
| Build or promote ISOs | `bluefin-iso` |

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

## Org pipeline — projectbluefin

### Repo map

```
common ──────────────────────────┐
(shared OCI layer)               │
                                 ▼
bluefin  (main→stable)       ←── images ──→ testsuite (e2e gate)
bluefin-lts (main→lts)       ←── images ──→ testsuite (e2e gate)
dakota  (main→:latest)       ←── images ──→ testsuite (e2e gate)
                                 │
                                 ▼
                                iso (installation media)
```

Each image repo pulls `ghcr.io/projectbluefin/common:latest` as a base layer.
testsuite gates `:latest` promotion in all three image repos.

### Issue lifecycle

`filed → approved → queued → claimed → done`

| Stage | How |
|---|---|
| `filed` | Issue opened |
| `approved` | Maintainer adds `status/approved` or comments `/approve` |
| `queued` | `queue/agent-ready` auto-added alongside approval |
| `claimed` | Comment `/claim` — assigned, removed from pool |
| `done` | Fix shipped + 3× `ujust verify` or maintainer override |

No PR activity in 7 days returns a claimed issue to the queue automatically.

### PR comment policy

One comment per PR event, max. Combine all findings. Never post a follow-up — edit the existing comment.
Never duplicate GitHub UI state (approvals, CI status).
Test reports: what ran + pass/fail + blockers only. No diff summaries.
@ mentions only when asking someone to do something specific. Never standalone.
When in doubt, post nothing.

### Mandatory gates

- `just check && pre-commit run --all-files` before every commit
- PR title: Conventional Commits format (`feat:`, `fix:`, `chore(deps):`, etc.)
- Attribution on every AI-authored commit: `Assisted-by: <Model> via <Tool>`
- Max 4 open PRs at a time per agent
- No WIP PRs


## Related projects

- Documentation: [projectbluefin/bluefin-docs](https://github.com/projectbluefin/bluefin-docs) / [docs.projectbluefin.io](https://docs.projectbluefin.io)
- LTS variant: [projectbluefin/bluefin-lts](https://github.com/projectbluefin/bluefin-lts)
- Common layer: [projectbluefin/common](https://github.com/projectbluefin/common)
