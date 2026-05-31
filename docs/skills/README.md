# docs/skills — Project Bluefin Agent Skills

These are the canonical, community-owned skill files for agents working in this repo.
They live here so any agent or contributor can load them without personal configuration.

## Skill router

| Task | File |
|------|------|
| Build, validate, or submit a PR | [build.md](build.md) |
| Debug a CI failure | [ci.md](ci.md) |
| Add, remove, or update a package | [packages.md](packages.md) |
| Cut a release or manage stream tags | [release.md](release.md) |
| Review or merge a Renovate PR | [renovate.md](renovate.md) |
| COPR repos, cosign, or security decisions | [security.md](security.md) |
| Understand image variants and stream matrix | [variants.md](variants.md) |
| Work on the LTS image | [lts.md](lts.md) |
| Build or promote ISOs | [iso.md](iso.md) |

## Contributing

Skills live in this repo, not in any personal configuration.
To update a skill, open a PR targeting `testing` and edit the relevant file directly.
Keep skill content factual, command-heavy, and free of personal paths or tooling references.
