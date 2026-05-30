# Contributing to Bluefin

Thanks for helping out!

Check the [Contributing Guide](https://docs.projectbluefin.io/contributing) for full contribution information, including the [architecture diagram](https://docs.projectbluefin.io/contributing#understanding-bluefins-architecture).

## Quick start

- This repository builds the OS images. Most user-facing changes belong in [@projectbluefin/common](https://github.com/projectbluefin/common).
- All PRs target the **`testing`** branch (the default branch).
- PR titles and commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
- Run `just check && pre-commit run --all-files` before pushing.
- AI-assisted commits must include an `Assisted-by:` footer (see `AGENTS.md`).
