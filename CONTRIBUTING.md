# Contributing to Bluefin

## Branch and stream workflow

### I want to submit a fix or feature — what do I do?

PR against the `main` branch. Do not PR directly against `stable` or `latest`. If your change is important and needs to ship immediately, apply the `cherry-pick` label to your PR and explain why in the description.

The `bluefin-backport-bot` will open a backport PR to `stable` automatically after your PR merges into `main`.

### Manual cherry-pick (if the bot is broken)

[The backport action](https://github.com/korthout/backport-action) powers the bot. If it fails, cherry-pick manually:

```bash
# Find the merge commit on main
git log --oneline main | head -20

git switch stable
git switch -c backport-my-fix
git cherry-pick -x <commit-sha>
```

Use the merge commit from `main`, not the PR branch commit, so the origin is traceable.

### Only `:stable` / `:latest` is broken but `:testing` is not

The fix still goes into `main` first. Rare exceptions exist when the feature was removed in `main` and only exists in `stable`.

## Promoting `main` to `stable` and `latest`

Every Tuesday at 06:00 UTC the `weekly-testing-promotion` workflow:
1. Verifies smoke e2e tests have passed on `main` HEAD
2. Runs the full developer + vanilla-gnome e2e suite
3. Fast-forwards `latest` and `stable` branches to `main`
4. Triggers the `stable` and `latest` image builds

## Branching for a new Fedora version

- Wait for the Fedora Beta announcement
- PR `ublue-os/akmods` for the new version
- Bump `testing_version` in `Justfile`
- Handle third-party repo breakage

## Promoting to a new `:stable` / `:latest`

- Wait for the official Fedora release (package freeze lifted)
- Wait for coreos:stable (~2 weeks post-Fedora) → PR `ublue-os/akmods`
- Bump workflow and Justfile version references in `main`
- Create a new `stable-f$N` branch and update branch protection rules

## Stream reference

| | `:stable` | `:latest` | `:testing` |
|---|---|---|---|
| Built from | `stable` branch | `latest` branch | `main` branch |
| Kernel | coreos-stable, pinned on regressions | Fedora default, pinned on bad regressions | Fedora default |
| Published | Weekly promotion + emergency manual trigger | Weekly promotion | On merges to `main` |
| Who should use it | Regular users | Enthusiasts | Testers, developers |
