#!/usr/bin/env python3

import sys
import json
import subprocess
import time
import re
import base64
import argparse
import logging
import warnings
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable, Any

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

IMAGE_CONFIGS = {
    "bluefin": {
        "registry": "ghcr.io/ublue-os/",
        "cosign_key": "https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/cosign.pub",
        "images": ["bluefin", "bluefin-dx"],
    },
    "aurora": {
        "registry": "ghcr.io/ublue-os/",
        "cosign_key": "https://raw.githubusercontent.com/ublue-os/aurora/refs/heads/main/cosign.pub",
        "images": ["aurora", "aurora-dx"],
    },
    "bluefin-lts": {
        "registry": "ghcr.io/ublue-os/",
        "cosign_key": "https://raw.githubusercontent.com/ublue-os/bluefin-lts/refs/heads/main/cosign.pub",
        "images": ["bluefin", "bluefin-dx"],
    },
    "aurora-lts": {
        "registry": "ghcr.io/ublue-os/",
        "cosign_key": "https://raw.githubusercontent.com/ublue-os/aurora-lts/refs/heads/main/cosign.pub",
        "images": ["aurora", "aurora-dx"],
    },
}

# Default family if none is specified
DEFAULT_FAMILY = "bluefin"

FEATURED_PACKAGES = {
    "kernel": "kernel",
    "gnome": "gnome-shell",
    "mesa": "mesa",
    "podman": "podman",
    "nvidia": "akmod-nvidia",
    "docker": "docker",
    "systemd": "systemd",
    "bootc": "bootc",
}

# Release variant labels for the changelog heading
VARIANT_LABELS = {
    "stable": "Stable Release",
    "lts": "LTS Release",
    "gts": "GTS Release",
    "beta": "Beta Release",
}

RETRIES = 3
RETRY_WAIT_S = 2.0

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------------
# Utilities
# ----------------------------------------------------------------------------


def run_cmd(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        return result.stdout
    else:
        raise Exception(
            f"Command failed\nCmd: {cmd}\nExit: {result.returncode}\nErr: {result.stderr}"
        )


def retry(n: int, f: Callable) -> Any:
    for attempt in range(1, n + 1):
        try:
            return f()
        except Exception as e:
            if attempt < n:
                log.warning(
                    f"Attempt {attempt}/{n} failed: {e}. Retrying in {RETRY_WAIT_S}s…"
                )
                time.sleep(RETRY_WAIT_S)
            else:
                raise


# ----------------------------------------------------------------------------
# SBOM Fetching
# ----------------------------------------------------------------------------


def fetch_manifest(registry: str, image: str, tag: str) -> dict:
    def _fetch():
        out = run_cmd(["skopeo", "inspect", f"docker://{registry}{image}:{tag}"])
        return json.loads(out)

    return retry(RETRIES, _fetch)


def get_digest(registry: str, image: str, tag: str) -> str:
    def _fetch():
        out = run_cmd(
            ["skopeo", "inspect", "--raw", f"docker://{registry}{image}:{tag}"]
        )
        manifest = json.loads(out)

        media_type = manifest.get("mediaType", "")
        # If it's an image index or manifest list, find the amd64 manifest digest
        if media_type in (
            "application/vnd.oci.image.index.v1+json",
            "application/vnd.docker.distribution.manifest.list.v2+json",
        ):
            for m in manifest.get("manifests", []):
                platform = m.get("platform", {})
                if (
                    platform.get("architecture") == "amd64"
                    and platform.get("os") == "linux"
                ):
                    return m.get("digest")
            raise ValueError(
                f"Could not find amd64 linux manifest in index for {image}:{tag}"
            )

        # Fallback to standard skopeo inspect for the actual digest
        out2 = run_cmd(["skopeo", "inspect", f"docker://{registry}{image}:{tag}"])
        return json.loads(out2).get("Digest")

    return retry(RETRIES, _fetch)


def extract_payloads(s: str) -> list[str]:
    """
    cosign verify-attestation can emit multiple JSON lines, one per attestation.
    Extract all payload values so we can find the SPDX one.
    """
    return re.findall(r'"payload"\s*:\s*"([^"]+)"', s)


def fetch_sbom(registry: str, cosign_key: str, image: str, digest: str) -> dict:
    def _fetch():
        cmd_stable = [
            "cosign",
            "verify-attestation",
            "--type",
            "spdxjson",
            "--key",
            cosign_key,
            f"{registry}{image}@{digest}",
        ]
        cmd_lts = [
            "cosign",
            "verify-attestation",
            "--type",
            "urn:ublue-os:attestation:spdx+json+zstd:v1",
            "--key",
            cosign_key,
            f"{registry}{image}@{digest}",
        ]

        try:
            raw = run_cmd(cmd_stable)
        except Exception as e_stable:
            log.debug(
                f"spdxjson attestation failed: {e_stable}. Trying zstd attestation..."
            )
            try:
                raw = run_cmd(cmd_lts)
            except Exception as e_lts:
                raise ValueError(
                    f"Failed to fetch any attestation. Stable error: {e_stable} | LTS error: {e_lts}"
                )

        payloads = extract_payloads(raw)
        if not payloads:
            raise ValueError("No payload found in attestation output.")

        # Iterate all payloads and return the first one that contains SPDX artifacts
        for payload_b64 in payloads:
            try:
                payload_bytes = base64.b64decode(payload_b64)
                payload_json = json.loads(payload_bytes.decode("utf-8"))

                if (
                    payload_json.get("predicateType")
                    == "urn:ublue-os:attestation:spdx+json+zstd:v1"
                ):
                    import tempfile

                    zstd_b64 = payload_json.get("predicate", {}).get("payload")
                    if zstd_b64:
                        zstd_bytes = base64.b64decode(zstd_b64)
                        with tempfile.NamedTemporaryFile() as tmp:
                            tmp.write(zstd_bytes)
                            tmp.flush()
                            spdx_json_str = run_cmd(["zstd", "-d", "-c", tmp.name])
                            predicate = json.loads(spdx_json_str)
                    else:
                        continue
                else:
                    predicate = payload_json.get("predicate", {})

                if predicate.get("artifacts") or predicate.get("packages"):
                    return predicate
            except Exception as e:
                log.warning(f"Skipping payload that failed to decode: {e}")
                continue

        raise ValueError("No valid SPDX predicate found among attestation payloads.")

    return retry(RETRIES, _fetch)


# ----------------------------------------------------------------------------
# Package Extraction
# ----------------------------------------------------------------------------

EPOCH_PATTERN = re.compile(r"^\d+:")
FEDORA_PATTERN = re.compile(r"\.fc\d+")


def normalize_version(v: str) -> str:
    v = EPOCH_PATTERN.sub("", v)
    v = FEDORA_PATTERN.sub("", v)
    return v


def parse_packages(sbom: dict) -> dict:
    pkg_map = {}
    for artifact in sbom.get("artifacts", []):
        if artifact.get("type") == "rpm":
            name = artifact.get("name")
            version = artifact.get("version")
            if name and version:
                pkg_map[name] = normalize_version(version)
            else:
                log.debug(
                    f"Skipping malformed artifact (missing name or version): {artifact}"
                )

    for pkg in sbom.get("packages", []):
        name = pkg.get("name")
        version = pkg.get("versionInfo")
        is_rpm = False
        for ext in pkg.get("externalRefs", []):
            if ext.get("referenceType") == "purl" and "pkg:rpm" in ext.get(
                "referenceLocator", ""
            ):
                is_rpm = True
                break
        if name and version and is_rpm:
            pkg_map[name] = normalize_version(version)

    return dict(sorted(pkg_map.items()))


def fetch_packages(registry: str, cosign_key: str, image: str, tag: str) -> dict:
    digest = get_digest(registry, image, tag)
    sbom = fetch_sbom(registry, cosign_key, image, digest)
    return parse_packages(sbom)


def build_release(registry: str, cosign_key: str, images: list[str], tag: str) -> dict:
    """Fetch packages for all images in parallel."""
    results = {}

    def _fetch_one(img):
        log.info(f"Fetching packages for {img}:{tag}…")
        return img, fetch_packages(registry, cosign_key, img, tag)

    with ThreadPoolExecutor(max_workers=len(images)) as executor:
        futures = {executor.submit(_fetch_one, img): img for img in images}
        for future in as_completed(futures):
            img, pkgs = future.result()  # raises on error
            results[img] = {"packages": pkgs}

    return results


# ----------------------------------------------------------------------------
# Diff Logic
# ----------------------------------------------------------------------------


def diff_packages(prev_pkgs: dict, curr_pkgs: dict) -> dict:
    prev_keys = set(prev_pkgs.keys())
    curr_keys = set(curr_pkgs.keys())

    added = {k: curr_pkgs[k] for k in curr_keys - prev_keys}
    removed = {k: prev_pkgs[k] for k in prev_keys - curr_keys}
    changed = {
        k: {"from": prev_pkgs[k], "to": curr_pkgs[k]}
        for k in prev_keys & curr_keys
        if prev_pkgs[k] != curr_pkgs[k]
    }

    return {
        "added": dict(sorted(added.items())),
        "removed": dict(sorted(removed.items())),
        "changed": dict(sorted(changed.items())),
    }


def diff_images(prev_release: dict, curr_release: dict) -> dict:
    result = {}
    for img, curr_data in curr_release.items():
        prev_pkgs = prev_release.get(img, {}).get("packages", {})
        result[img] = diff_packages(prev_pkgs, curr_data["packages"])
    return result


def common_packages(release: dict) -> list:
    if not release:
        return []
    package_sets = [set(data["packages"].keys()) for data in release.values()]
    return sorted(set.intersection(*package_sets))


# ----------------------------------------------------------------------------
# Git Commit Extraction
# ----------------------------------------------------------------------------


def fetch_commits(prev_tag: str, curr_tag: str) -> list[dict]:
    try:
        out = run_cmd(
            ["git", "log", "--pretty=format:%H;%s;%an", f"{prev_tag}..{curr_tag}"]
        )
    except Exception as e:
        log.warning(
            f"Could not fetch git commits between {prev_tag} and {curr_tag}: {e}"
        )
        return []

    commits = []
    for line in out.strip().splitlines():
        if line:
            parts = line.split(";", 2)
            if len(parts) == 3:
                commits.append(
                    {"hash": parts[0], "subject": parts[1], "author": parts[2]}
                )
    return commits


# ----------------------------------------------------------------------------
# Tag Discovery
# ----------------------------------------------------------------------------


def get_tag_list(registry: str, image: str, tag: str) -> list[str]:
    """Fetch all tags for the given image from the registry."""
    manifest = fetch_manifest(registry, image, tag)
    return manifest.get("RepoTags", [])


def discover_tags(family: str, stream: str) -> tuple[str, str]:
    """
    Find the latest two tags for the given stream (e.g. 'stable', 'latest').
    Returns (prev_tag, curr_tag).
    """
    config = IMAGE_CONFIGS.get(family)
    if not config:
        raise ValueError(f"Unknown family: {family}")

    registry = config["registry"]
    # Use the first image in the list to find tags
    image = config["images"][0]

    # Map 'stable' stream to the tag to inspect for RepoTags (usually just the stream name)
    # The old script inspected image:stream to get RepoTags.

    log.info(f"Discovering tags for {family} {stream}...")
    tags = get_tag_list(registry, image, stream)

    # Filter tags: looking for {stream}-YYYYMMDD or similar patterns.
    # The old script used regex: f"{target}-\d\d\d+" (where target=stable)
    # Examples: stable-20260217

    # We also need to filter out tags ending in .0 if strictly following old logic,
    # but let's just look for the date pattern.

    # Pattern: ^stream[-.](?:\d+\.)?\d{8}(?:\.\d+)?$ (matches stable-20250101, stable-43.20250101, stable-20250101.1, lts.20250101)

    pattern = re.compile(rf"^{stream}[-.](?:\d+\.)?\d{{8}}(?:\.\d+)?$")

    filtered_tags = sorted([t for t in tags if pattern.match(t)])

    if len(filtered_tags) < 2:
        raise ValueError(
            f"Found fewer than 2 tags matching pattern '{pattern.pattern}' for {stream}. Found: {filtered_tags}"
        )

    prev = filtered_tags[-2]
    curr = filtered_tags[-1]

    log.info(f"Discovered tags: prev={prev}, curr={curr}")
    return prev, curr


# ----------------------------------------------------------------------------
# Markdown Generation
# ----------------------------------------------------------------------------


def infer_variant_label(tag: str) -> str:
    """
    Derive a human-readable release label from the tag, e.g.:
      'stable-20250101' -> 'Stable Release'
      'lts-20250101'    -> 'LTS Release'
      'gts-20250101'    -> 'GTS Release'
    Falls back to the raw tag if no known variant prefix is matched.
    """
    prefix = tag.split("-")[0].lower()
    return VARIANT_LABELS.get(prefix, f"{prefix.upper()} Release")


def render_changelog(data: dict, handwritten: str = "") -> str:
    prev_tag = data["prev-tag"]
    curr_tag = data["curr-tag"]
    variant_label = infer_variant_label(curr_tag)

    lines = [f"# 🦕 {curr_tag}: {variant_label}", ""]

    if handwritten:
        lines.append(handwritten)
        lines.append("")

    lines.extend(
        [
            f"This is an automatically generated changelog for release `{curr_tag}`.",
            "",
            f"From previous version `{prev_tag}` there have been the following changes. **Only packages that actually changed are shown.**",
            "",
        ]
    )

    for img, pkg_diff in data["diff"].items():
        lines.append(f"## 📦 {img} Packages")
        lines.append("")

        if pkg_diff.get("added"):
            lines.append("### ✨ Added")
            lines.append("| Package | Version |")
            lines.append("| --- | --- |")
            for name, version in pkg_diff["added"].items():
                lines.append(f"| {name} | {version} |")
            lines.append("")

        if pkg_diff.get("removed"):
            lines.append("### ❌ Removed")
            lines.append("| Package | Version |")
            lines.append("| --- | --- |")
            for name, version in pkg_diff["removed"].items():
                lines.append(f"| {name} | {version} |")
            lines.append("")

        if pkg_diff.get("changed"):
            lines.append("### 🔄 Changed")
            lines.append("| Package | Version |")
            lines.append("| --- | --- |")
            for name, changes in pkg_diff["changed"].items():
                lines.append(f"| {name} | {changes['from']} ➡️ {changes['to']} |")
            lines.append("")

    commits = data.get("commits", [])
    if commits:
        lines.append("## 📜 Commits")
        lines.append("| Hash | Subject | Author |")
        lines.append("| --- | --- | --- |")
        for commit in commits:
            short_hash = commit["hash"][:7]
            lines.append(
                f"| 🔹 **[{short_hash}](https://github.com/ublue-os/bluefin/commit/{commit['hash']})** | {commit['subject']} | {commit['author']} |"
            )
        lines.append("")

    return "\n".join(lines)


# ----------------------------------------------------------------------------
# Public API
# ----------------------------------------------------------------------------


def extract_featured(packages: dict) -> dict:
    featured = {}
    for label, pkg_name in FEATURED_PACKAGES.items():
        if pkg_name in packages:
            featured[label] = packages[pkg_name]
    return featured


def build_website_data(curr_release: dict) -> dict:
    return {
        img: {"featured": extract_featured(data["packages"])}
        for img, data in curr_release.items()
    }


def build_release_data(
    prev_tag: str,
    curr_tag: str,
    family: str = DEFAULT_FAMILY,
    images: list[str] | None = None,
) -> dict:
    config = IMAGE_CONFIGS.get(family)
    if config is None:
        raise ValueError(
            f"Unknown image family '{family}'. Known families: {list(IMAGE_CONFIGS.keys())}"
        )

    registry = config["registry"]
    cosign_key = config["cosign_key"]
    images = images or config["images"]

    prev_release = build_release(registry, cosign_key, images, prev_tag)
    curr_release = build_release(registry, cosign_key, images, curr_tag)
    diff = diff_images(prev_release, curr_release)
    commits = fetch_commits(prev_tag, curr_tag)
    website = build_website_data(curr_release)

    return {
        "family": family,
        "prev-tag": prev_tag,
        "curr-tag": curr_tag,
        "images": images,
        "releases": {"previous": prev_release, "current": curr_release},
        "common-packages": common_packages(curr_release),
        "diff": diff,
        "commits": commits,
        "website": website,
    }


# ----------------------------------------------------------------------------
# CLI
# ----------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a changelog between two Bluefin/Aurora image releases.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    # Make prev_tag/curr_tag optional if stream is provided
    parser.add_argument(
        "prev_tag", nargs="?", help="Previous release tag (e.g. stable-20250101)"
    )
    parser.add_argument(
        "curr_tag", nargs="?", help="Current release tag (e.g. stable-20250201)"
    )

    parser.add_argument(
        "--stream",
        help="Release stream (e.g. stable, latest) to automatically discover tags",
    )

    parser.add_argument(
        "--family",
        default=DEFAULT_FAMILY,
        choices=list(IMAGE_CONFIGS.keys()),
        help="Image family to generate the changelog for",
    )
    parser.add_argument(
        "--images",
        nargs="+",
        metavar="IMAGE",
        help="Override the default image list for the chosen family",
    )
    parser.add_argument(
        "--output",
        "-o",
        metavar="FILE",
        help="Output file path (defaults to changelog.md or changelog.json)",
    )
    parser.add_argument(
        "--output-env",
        metavar="FILE",
        help="Output environment file (TITLE=... TAG=...)",
    )
    parser.add_argument(
        "--handwritten",
        help="Optional handwritten text to include at the top of the changelog",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw JSON instead of Markdown",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable debug logging",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Validation
    if args.stream:
        if args.prev_tag or args.curr_tag:
            log.warning(
                "Arguments 'prev_tag' and 'curr_tag' are ignored when '--stream' is provided."
            )

        prev_tag, curr_tag = discover_tags(args.family, args.stream)
    else:
        if not args.prev_tag or not args.curr_tag:
            log.error(
                "Either '--stream' OR 'prev_tag' and 'curr_tag' must be provided."
            )
            sys.exit(1)
        prev_tag = args.prev_tag
        curr_tag = args.curr_tag

    out_file = args.output or ("changelog.json" if args.json else "changelog.md")

    release_data = build_release_data(
        prev_tag=prev_tag,
        curr_tag=curr_tag,
        family=args.family,
        images=args.images,
    )

    if args.json:
        with open(out_file, "w") as f:
            json.dump(release_data, f, indent=2)
        log.info(f"✅ JSON written to {out_file}")
    else:
        rendered_md = render_changelog(release_data, handwritten=args.handwritten)
        with open(out_file, "w") as f:
            f.write(rendered_md)
        log.info(f"✅ Markdown written to {out_file}")

    if args.output_env:
        # Generate title similar to old script logic
        variant_label = infer_variant_label(curr_tag)
        title = f"{curr_tag}: {variant_label}"
        with open(args.output_env, "w") as f:
            f.write(f'TITLE="{title}"\nTAG={curr_tag}\n')
        log.info(f"✅ Env file written to {args.output_env}")


if __name__ == "__main__":
    main()
