#!/usr/bin/env python3
"""
Generate a changelog between two specific GTS tags and post as a GitHub issue.
This script is specifically designed to handle Fedora version transitions in GTS builds.
"""

from itertools import product
import subprocess
import json
import time
from typing import Any
import re
from collections import defaultdict
import os
import sys

REGISTRY = "docker://ghcr.io/ublue-os/"

IMAGE_MATRIX = {
    "experience": ["base", "dx"],
    "de": ["gnome"],
    "image_flavor": ["main", "nvidia"],
}

RETRIES = 3
RETRY_WAIT = 5
FEDORA_PATTERN = re.compile(r"\.fc\d\d")

PATTERN_ADD = "\n| ✨ | {name} | | {version} |"
PATTERN_CHANGE = "\n| 🔄 | {name} | {prev} | {new} |"
PATTERN_REMOVE = "\n| ❌ | {name} | {version} | |"
PATTERN_PKGREL_CHANGED = "{prev} ➡️ {new}"
PATTERN_PKGREL = "{version}"
COMMON_PAT = "### All Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n"
OTHER_NAMES = {
    "base": "### Base Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "dx": "### [Dev Experience Images](https://docs.projectbluefin.io/bluefin-dx)\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "gnome": "### [Bluefin Images](https://projectbluefin.io/)\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "nvidia": "### Nvidia Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
}

COMMITS_FORMAT = "### Commits\n| Hash | Subject |\n| --- | --- |{commits}\n\n"
COMMIT_FORMAT = "\n| **[{short}](https://github.com/ublue-os/bluefin/commit/{githash})** | {subject} |"

CHANGELOG_TITLE = "GTS Changelog: {prev_tag} → {curr_tag}"
CHANGELOG_FORMAT = """\
From GTS version `{prev_tag}` (Fedora {prev_fedora}) to `{curr_tag}` (Fedora {curr_fedora}), there have been the following changes. **One package per new version shown.**

### Major packages
| Name | Version |
| --- | --- |
| **Kernel** | {pkgrel:kernel} |
| **Gnome** | {pkgrel:gnome-shell} |
| **Mesa** | {pkgrel:mesa-filesystem} |
| **Podman** | {pkgrel:podman} |
| **Nvidia** | {pkgrel:nvidia-driver} |

### Major DX packages
| Name | Version |
| --- | --- |
| **Incus** | {pkgrel:incus} |
| **Docker** | {pkgrel:docker-ce} |

{changes}

### How to rebase
For current users, type the following to rebase to this version:
```bash
# Get Image Name
IMAGE_NAME=$(jq -r '.["image-name"]' < /usr/share/ublue-os/image-info.json)

# For GTS Stream
sudo bootc switch --enforce-container-sigpolicy ghcr.io/ublue-os/$IMAGE_NAME:gts

# For this Specific Image:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/ublue-os/$IMAGE_NAME:{curr_tag}
```

### Documentation
Be sure to read the [documentation](https://docs.projectbluefin.io/) for more information
on how to use your cloud native system.
"""

BLACKLIST_VERSIONS = [
    "kernel",
    "gnome-shell",
    "mesa-filesystem",
    "podman",
    "docker-ce",
    "incus",
    "devpod",
    "nvidia-driver"
]


def get_images(target: str):
    """Generate image names based on the matrix."""
    for experience, de, image_flavor in product(*IMAGE_MATRIX.values()):
        img = ""
        if de == "gnome":
            img += "bluefin"

        if experience == "dx":
            img += "-dx"

        if image_flavor != "main":
            img += "-"
            img += image_flavor

        yield img, experience, de, image_flavor


def get_manifest(tag: str, img: str):
    """Get manifest for a specific image and tag."""
    print(f"Getting {img}:{tag} manifest.")
    for i in range(RETRIES):
        try:
            output = subprocess.run(
                ["skopeo", "inspect", REGISTRY + img + ":" + tag],
                check=True,
                stdout=subprocess.PIPE,
            ).stdout
            return json.loads(output)
        except subprocess.CalledProcessError:
            print(
                f"Failed to get {img}:{tag}, retrying in {RETRY_WAIT} seconds ({i+1}/{RETRIES})"
            )
            time.sleep(RETRY_WAIT)
    print(f"Failed to get {img}:{tag} after {RETRIES} retries")
    return None


def get_manifests_for_tag(tag: str):
    """Get manifests for all images with a specific tag."""
    out = {}
    imgs = list(get_images("gts"))
    for j, (img, _, _, _) in enumerate(imgs):
        manifest = get_manifest(tag, img)
        if manifest:
            out[img] = manifest
    return out


def get_packages(manifests: dict[str, Any]):
    """Extract packages from manifests."""
    packages = {}
    for img, manifest in manifests.items():
        try:
            packages[img] = json.loads(manifest["Labels"]["dev.hhd.rechunk.info"])[
                "packages"
            ]
        except Exception as e:
            print(f"Failed to get packages for {img}:\n{e}")
    return packages


def get_package_groups(prev: dict[str, Any], manifests: dict[str, Any]):
    """Categorize packages into common and other groups."""
    common = set()
    others = {k: set() for k in OTHER_NAMES.keys()}

    npkg = get_packages(manifests)
    ppkg = get_packages(prev)

    keys = set(npkg.keys()) | set(ppkg.keys())
    pkg = defaultdict(set)
    for k in keys:
        pkg[k] = set(npkg.get(k, {})) | set(ppkg.get(k, {}))

    # Find common packages
    first = True
    for img, experience, de, image_flavor in get_images("gts"):
        if img not in pkg:
            continue

        if first:
            for p in pkg[img]:
                common.add(p)
        else:
            for c in common.copy():
                if c not in pkg[img]:
                    common.remove(c)

        first = False

    # Find other packages
    for t, other in others.items():
        first = True
        for img, experience, de, image_flavor in get_images("gts"):
            if img not in pkg:
                continue

            if t == "nvidia" and "nvidia" not in image_flavor:
                continue
            if t == "gnome" and de != "gnome":
                continue
            if t == "base" and experience != "base":
                continue
            if t == "dx" and experience != "dx":
                continue

            if first:
                for p in pkg[img]:
                    if p not in common:
                        other.add(p)
            else:
                for c in other.copy():
                    if c not in pkg[img]:
                        other.remove(c)

            first = False

    return sorted(common), {k: sorted(v) for k, v in others.items()}


def get_versions(manifests: dict[str, Any]):
    """Extract package versions from manifests."""
    versions = {}
    pkgs = get_packages(manifests)
    for img_pkgs in pkgs.values():
        for pkg, v in img_pkgs.items():
            v = re.sub(FEDORA_PATTERN, "", v)
            v = re.sub(r"\.switcheroo", "", v)
            versions[pkg] = v
    return versions


def calculate_changes(pkgs: list[str], prev: dict[str, str], curr: dict[str, str]):
    """Calculate package changes between two versions."""
    added = []
    changed = []
    removed = []

    blacklist_ver = set([curr.get(v, None) for v in BLACKLIST_VERSIONS])

    for pkg in pkgs:
        # Clearup changelog by removing mentioned packages
        if pkg in BLACKLIST_VERSIONS:
            continue
        if pkg in curr and curr.get(pkg, None) in blacklist_ver:
            continue
        if pkg in prev and prev.get(pkg, None) in blacklist_ver:
            continue

        if pkg not in prev:
            added.append(pkg)
        elif pkg not in curr:
            removed.append(pkg)
        elif prev[pkg] != curr[pkg]:
            changed.append(pkg)

        blacklist_ver.add(curr.get(pkg, None))
        blacklist_ver.add(prev.get(pkg, None))

    out = ""
    for pkg in added:
        out += PATTERN_ADD.format(name=pkg, version=curr[pkg])
    for pkg in changed:
        out += PATTERN_CHANGE.format(name=pkg, prev=prev[pkg], new=curr[pkg])
    for pkg in removed:
        out += PATTERN_REMOVE.format(name=pkg, version=prev[pkg])
    return out


def get_commits(prev_manifests, manifests, workdir: str):
    """Get commit history between two manifests."""
    try:
        start = next(iter(prev_manifests.values()))["Labels"][
            "org.opencontainers.image.revision"
        ]
        finish = next(iter(manifests.values()))["Labels"][
            "org.opencontainers.image.revision"
        ]

        commits = subprocess.run(
            [
                "git",
                "-C",
                workdir,
                "log",
                "--pretty=format:%H %h %s",
                f"{start}..{finish}",
            ],
            check=True,
            stdout=subprocess.PIPE,
        ).stdout.decode("utf-8")

        out = ""
        for commit in commits.split("\n"):
            if not commit:
                continue
            githash, short, subject = commit.split(" ", 2)

            if subject.lower().startswith("merge"):
                continue
            if subject.lower().startswith("chore"):
                continue

            out += (
                COMMIT_FORMAT.replace("{short}", short)
                .replace("{subject}", subject)
                .replace("{githash}", githash)
            )

        if out:
            return COMMITS_FORMAT.format(commits=out)
        return ""
    except Exception as e:
        print(f"Failed to get commits:\n{e}")
        return ""


def extract_fedora_version(tag: str) -> str:
    """Extract Fedora version from tag (e.g., 'gts-41.20251024' -> '41')."""
    match = re.search(r'-(\d+)\.', tag)
    if match:
        return match.group(1)
    return "unknown"


def generate_changelog(
    workdir: str,
    prev_tag: str,
    curr_tag: str,
    prev_manifests,
    manifests,
):
    """Generate a complete changelog between two tags."""
    common, others = get_package_groups(prev_manifests, manifests)
    versions = get_versions(manifests)
    prev_versions = get_versions(prev_manifests)

    prev_fedora = extract_fedora_version(prev_tag)
    curr_fedora = extract_fedora_version(curr_tag)

    title = CHANGELOG_TITLE.format(prev_tag=prev_tag, curr_tag=curr_tag)

    changelog = CHANGELOG_FORMAT

    changelog = (
        changelog.replace("{prev_tag}", prev_tag)
        .replace("{curr_tag}", curr_tag)
        .replace("{prev_fedora}", prev_fedora)
        .replace("{curr_fedora}", curr_fedora)
    )

    for pkg, v in versions.items():
        if pkg not in prev_versions or prev_versions[pkg] == v:
            changelog = changelog.replace(
                "{pkgrel:" + pkg + "}", PATTERN_PKGREL.format(version=v)
            )
        else:
            changelog = changelog.replace(
                "{pkgrel:" + pkg + "}",
                PATTERN_PKGREL_CHANGED.format(prev=prev_versions[pkg], new=v),
            )

    changes = ""
    changes += get_commits(prev_manifests, manifests, workdir)
    common = calculate_changes(common, prev_versions, versions)
    if common:
        changes += COMMON_PAT.format(changes=common)
    for k, v in others.items():
        chg = calculate_changes(v, prev_versions, versions)
        if chg:
            changes += OTHER_NAMES[k].format(changes=chg)

    changelog = changelog.replace("{changes}", changes)

    return title, changelog


def create_github_issue(title: str, body: str, repo: str, token: str):
    """Create a GitHub issue with the changelog."""
    import requests

    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
    }

    data = {
        "title": title,
        "body": body,
        "labels": ["changelog", "gts", "automated"]
    }

    url = f"https://api.github.com/repos/{repo}/issues"

    response = requests.post(url, headers=headers, json=data)

    if response.status_code == 201:
        issue_data = response.json()
        print(f"Issue created successfully: {issue_data['html_url']}")
        return issue_data['html_url']
    else:
        print(f"Failed to create issue: {response.status_code}")
        print(f"Response: {response.text}")
        sys.exit(1)


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate GTS changelog and create GitHub issue"
    )
    parser.add_argument("prev_tag", help="Previous GTS tag (e.g., gts-41.20251024)")
    parser.add_argument("curr_tag", help="Current GTS tag (e.g., gts-42.20251028)")
    parser.add_argument("--workdir", help="Git directory for commits", default=".")
    parser.add_argument("--repo", help="GitHub repository (owner/repo)", default="ublue-os/bluefin")
    parser.add_argument("--token", help="GitHub token (or use GITHUB_TOKEN env var)")
    parser.add_argument("--output", help="Output file for changelog (optional)")
    args = parser.parse_args()

    # Get GitHub token
    token = args.token or os.environ.get("GITHUB_TOKEN")
    if not token:
        print("Error: GitHub token required (use --token or GITHUB_TOKEN env var)")
        sys.exit(1)

    print(f"Generating changelog from {args.prev_tag} to {args.curr_tag}")

    # Get manifests for both tags
    print("\nFetching previous tag manifests...")
    prev_manifests = get_manifests_for_tag(args.prev_tag)
    if not prev_manifests:
        print(f"Error: No manifests found for {args.prev_tag}")
        sys.exit(1)

    print("\nFetching current tag manifests...")
    curr_manifests = get_manifests_for_tag(args.curr_tag)
    if not curr_manifests:
        print(f"Error: No manifests found for {args.curr_tag}")
        sys.exit(1)

    # Generate changelog
    print("\nGenerating changelog...")
    title, changelog = generate_changelog(
        args.workdir,
        args.prev_tag,
        args.curr_tag,
        prev_manifests,
        curr_manifests,
    )

    print(f"\n{'='*80}")
    print(f"TITLE: {title}")
    print(f"{'='*80}")
    print(changelog)
    print(f"{'='*80}\n")

    # Save to file if requested
    if args.output:
        with open(args.output, "w") as f:
            f.write(changelog)
        print(f"Changelog saved to {args.output}")

    # Create GitHub issue
    print("\nCreating GitHub issue...")
    issue_url = create_github_issue(title, changelog, args.repo, token)
    print(f"\n✅ Changelog issue created: {issue_url}")


if __name__ == "__main__":
    main()
