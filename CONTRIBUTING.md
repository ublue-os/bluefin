# Contributing to Bluefin

## Branch and stream workflow

### I want to submit a fix or feature — what do I do?

PR against the `testing` branch. Do not PR directly against `stable`. If your change is important and needs to ship immediately, apply the `cherry-pick` label to your PR and explain why in the description.

The `bluefin-backport-bot` will open a backport PR to `stable` automatically after your PR merges into `testing`.

### Manual cherry-pick (if the bot is broken)

[The backport action](https://github.com/korthout/backport-action) powers the bot. If it fails, cherry-pick manually:

```bash
# Find the merge commit on testing
git log --oneline testing | head -20

git switch stable
git switch -c backport-my-fix
git cherry-pick -x <commit-sha>
```

Use the merge commit from `testing`, not the PR branch commit, so the origin is traceable.

### Only `:stable` / `:latest` is broken but `:testing` is not

The fix still goes into `testing` first. Rare exceptions exist when the feature was removed in `testing` and only exists in `stable`.

## Merging `testing` changes into `stable`

A pull bot opens PRs to merge `testing` → `stable` on each new commit. These can be merged any time there are no known regressions on `:testing`.

## Branching for a new Fedora version

- Wait for the Fedora Beta announcement
- PR `ublue-os/akmods` for the new version
- Bump `testing_version` in `Justfile`
- Handle third-party repo breakage

## Promoting to a new `:stable` / `:latest`

- Wait for the official Fedora release (package freeze lifted)
- Wait for coreos:stable (~2 weeks post-Fedora) → PR `ublue-os/akmods`
- Bump workflow and Justfile version references in `testing`
- Create a new `stable-f$N` branch and update branch protection rules

## Stream reference

| | `:stable` | `:latest` | `:testing` |
|---|---|---|---|
| Built from | `stable` branch | `testing` branch | `testing` branch |
| Kernel | coreos-stable, pinned on regressions | Fedora default, pinned on bad regressions | Fedora default |
| Published | Weekly cron + emergency manual trigger | On merges to `testing` | On merges to `testing` |
| Who should use it | Regular users | Enthusiasts | Testers, developers |
