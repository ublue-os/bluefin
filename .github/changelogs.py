from itertools import product
import subprocess
import json
import time
from typing import Any
import re
from collections import defaultdict

REGISTRY = "docker://ghcr.io/ublue-os/"

IMAGE_MATRIX_LATEST = {
    "experience": ["base", "dx"],
    "de": ["kde", "gnome"],
    "image_flavor": ["main", "nvidia", "hwe", "hwe-nvidia"],
}
IMAGE_MATRIX_GTS = {
    "experience": ["base", "dx"],
    "de": ["gnome"],
    "image_flavor": ["main", "nvidia"],
}
IMAGE_MATRIX = {
    "experience": ["base", "dx"],
    "de": ["kde", "gnome"],
    "image_flavor": ["main", "nvidia"],
}

RETRIES = 3
RETRY_WAIT = 5
FEDORA_PATTERN = re.compile(r"\.fc\d\d")
START_PATTERN = lambda target: re.compile(rf"{target}-\d\d\d+")

PATTERN_ADD = "\n| ✨ | {name} | | {version} |"
PATTERN_CHANGE = "\n| 🔄 | {name} | {prev} | {new} |"
PATTERN_REMOVE = "\n| ❌ | {name} | {version} | |"
PATTERN_PKGREL_CHANGED = "{prev} ➡️ {new}"
PATTERN_PKGREL = "{version}"
COMMON_PAT = "### All Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n"
OTHER_NAMES = {
    "base": "### Base Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "dx": "### [Dev Experience Images](https://docs.projectbluefin.io/bluefin-dx)\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "kde": "### [Aurora Images](https://getaurora.dev/)\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "gnome": "### [Bluefin Images](https://projectbluefin.io/)\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "nvidia": "### Nvidia Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
    "hwe": "### HWE Images\n| | Name | Previous | New |\n| --- | --- | --- | --- |{changes}\n\n",
}

COMMITS_FORMAT = "### Commits\n| Hash | Subject |\n| --- | --- |{commits}\n\n"
COMMIT_FORMAT = "\n| **[{short}](https://github.com/ublue-os/bluefin/commit/{githash})** | {subject} |"

CHANGELOG_TITLE = "{tag}: {pretty}"
CHANGELOG_FORMAT = """\
{handwritten}

From previous `{target}` version `{prev}` there have been the following changes. **One package per new version shown.**

### Major packages
| Name | Version |
| --- | --- |
| **Kernel** | {pkgrel:kernel} |
| **Gnome** | {pkgrel:gnome-control-center-filesystem} |
| **KDE** | {pkgrel:plasma-desktop} |
| **Mesa** | {pkgrel:mesa-filesystem} |
| **Podman** | {pkgrel:podman} |

### Major DX packages
| Name | Version |
| --- | --- |
| **Incus** | {pkgrel:incus} |
| **Docker** | {pkgrel:docker-ce} |
| **Devpod** | {pkgrel:devpod} |

{changes}

### How to rebase
For current users, type the following to rebase to this version:
```bash
# Get Image Name
IMAGE_NAME=$(jq -r '.["image-name"]' < /usr/share/ublue-os/image-info.json)

# For this Stream
sudo bootc switch --enforce-container-sigpolicy ghcr.io/ublue-os/$IMAGE_NAME:{target}

# For this Specific Image:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/ublue-os/$IMAGE_NAME:{curr}
```

### Documentation
Be sure to read the [documentation](https://docs.projectbluefin.io/) for more information
on how to use your cloud native system.
"""
HANDWRITTEN_PLACEHOLDER = """\
This is an automatically generated changelog for release `{curr}`."""

BLACKLIST_VERSIONS = [
    "kernel",
    "gnome-control-center-filesystem",
    "plasma-desktop",
    "mesa-filesystem",
    "podman",
    "docker-ce",
    "incus",
    "devpod"
]


def get_images(target: str):
    if "latest" in target:
        matrix = IMAGE_MATRIX_LATEST
    elif "gts" in target:
        matrix = IMAGE_MATRIX_GTS
    else:
        matrix = IMAGE_MATRIX

    for experience, de, image_flavor in product(*matrix.values()):
        img = ""
        if de == "gnome":
            img += "bluefin"
        elif de == "kde":
            img += "aurora"

        if experience == "dx":
            img += "-dx"

        if image_flavor != "main":
            img += "-"
            img += image_flavor

        yield img, experience, de, image_flavor


def get_manifests(target: str):
    out = {}
    imgs = list(get_images(target))
    for j, (img, _, _, _) in enumerate(imgs):
        output = None
        print(f"Getting {img}:{target} manifest ({j+1}/{len(imgs)}).")
        for i in range(RETRIES):
            try:
                output = subprocess.run(
                    ["skopeo", "inspect", REGISTRY + img + ":" + target],
                    check=True,
                    stdout=subprocess.PIPE,
                ).stdout
                break
            except subprocess.CalledProcessError:
                print(
                    f"Failed to get {img}:{target}, retrying in {RETRY_WAIT} seconds ({i+1}/{RETRIES})"
                )
                time.sleep(RETRY_WAIT)
        if output is None:
            print(f"Failed to get {img}:{target}, skipping")
            continue
        out[img] = json.loads(output)
    return out


def get_tags(target: str, manifests: dict[str, Any]):
    tags = set()

    for manifest in manifests.values():
        for tag in manifest["RepoTags"]:
            # Tags ending with .0 should not exist
            if tag.endswith(".0"):
                continue
            if re.match(START_PATTERN(target), tag):
                tags.add(tag)

    tags = list(sorted(tags))
    if not len(tags) > 2:
        print("No current and previous tags found")
        exit(1)
    return tags[-2], tags[-1]


def get_packages(manifests: dict[str, Any]):
    packages = {}
    for img, manifest in manifests.items():
        try:
            packages[img] = json.loads(manifest["Labels"]["dev.hhd.rechunk.info"])[
                "packages"
            ]
        except Exception as e:
            print(f"Failed to get packages for {img}:\n{e}")
    return packages


def get_package_groups(target: str, prev: dict[str, Any], manifests: dict[str, Any]):
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
    for img, experience, de, image_flavor in get_images(target):
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
        for img, experience, de, image_flavor in get_images(target):
            if img not in pkg:
                continue

            if t == "hwe" and "hwe" not in image_flavor:
                continue
            if t == "nvidia" and "nvidia" not in image_flavor:
                continue
            if t == "kde" and de != "kde":
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
    versions = {}
    pkgs = get_packages(manifests)
    for img_pkgs in pkgs.values():
        for pkg, v in img_pkgs.items():
            versions[pkg] = re.sub(FEDORA_PATTERN, "", v)
    return versions


def calculate_changes(pkgs: list[str], prev: dict[str, str], curr: dict[str, str]):
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


def generate_changelog(
    handwritten: str | None,
    target: str,
    pretty: str | None,
    workdir: str,
    prev_manifests,
    manifests,
):
    common, others = get_package_groups(target, prev_manifests, manifests)
    versions = get_versions(manifests)
    prev_versions = get_versions(prev_manifests)

    prev, curr = get_tags(target, manifests)

    if not pretty:
        # Generate pretty version since we dont have it
        try:
            finish: str = next(iter(manifests.values()))["Labels"][
                "org.opencontainers.image.revision"
            ]
        except Exception as e:
            print(f"Failed to get finish hash:\n{e}")
            finish = ""
        try:
            linux: str = next(iter(manifests.values()))["Labels"][
                "ostree.linux"
            ]
            start=linux.find(".fc") + 3
            fedora_version=linux[start:start+2]
        except Exception as e:
            print(f"Failed to get linux version:\n{e}")
            fedora_version = ""

        # Remove .0 from curr
        curr_pretty = re.sub(r"\.\d{1,2}$", "", curr)
        # Remove target- from curr
        curr_pretty = re.sub(rf"^[a-z]+-|^[0-9]+-", "", curr_pretty)
        if target == "stable-daily":
            curr_pretty = re.sub(rf"^[a-z]+-", "", curr_pretty)
        if not fedora_version + "." in curr_pretty:
            curr_pretty=fedora_version + "." + curr_pretty
        pretty = target.capitalize()
        pretty += " (F" + curr_pretty
        if finish:
            pretty += ", #" + finish[:7]
        pretty += ")"

    title = CHANGELOG_TITLE.format_map(defaultdict(str, tag=curr, pretty=pretty))

    changelog = CHANGELOG_FORMAT

    changelog = (
        changelog.replace("{handwritten}", handwritten if handwritten else HANDWRITTEN_PLACEHOLDER)
        .replace("{target}", target)
        .replace("{prev}", prev)
        .replace("{curr}", curr)
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


def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("target", help="Target tag")
    parser.add_argument("output", help="Output environment file")
    parser.add_argument("changelog", help="Output changelog file")
    parser.add_argument("--pretty", help="Subject for the changelog")
    parser.add_argument("--workdir", help="Git directory for commits")
    parser.add_argument("--handwritten", help="Handwritten changelog")
    args = parser.parse_args()

    # Remove refs/tags, refs/heads, refs/remotes e.g.
    # Tags cannot include / anyway.
    target = args.target.split('/')[-1]

    if target == "main":
        target = "stable"

    manifests = get_manifests(target)
    prev, curr = get_tags(target, manifests)
    print(f"Previous tag: {prev}")
    print(f" Current tag: {curr}")

    prev_manifests = get_manifests(prev)
    title, changelog = generate_changelog(
        args.handwritten,
        target,
        args.pretty,
        args.workdir,
        prev_manifests,
        manifests,
    )

    print(f"Changelog:\n# {title}\n{changelog}")
    print(f"\nOutput:\nTITLE=\"{title}\"\nTAG={curr}")

    with open(args.changelog, "w") as f:
        f.write(changelog)

    with open(args.output, "w") as f:
        f.write(f'TITLE="{title}"\nTAG={curr}\n')


if __name__ == "__main__":
    main()
