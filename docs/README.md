# Documentation Assets

This directory contains documentation files that can be used by the [ublue-os/bluefin-docs](https://github.com/ublue-os/bluefin-docs) repository and other documentation sources.

## Files

### system-requirements.md
Complete system requirements documentation for Bluefin, based on upstream Fedora documentation with adjustments for Bluefin's cloud-native desktop environment. Key changes include bumping the RAM requirement to 16 GB to support container development workflows.

### requirements-snippet.md
Concise system requirements snippet suitable for inclusion in installation guides, README files, and other documentation where space is limited.

## Usage

These files can be:
- Referenced or included in the main bluefin-docs repository
- Used in installation guides and getting started documentation
- Incorporated into blog posts and announcements about system requirements
- Used as a basis for FAQ entries about hardware compatibility

## Maintenance

When updating these requirements:
1. Ensure consistency between the full documentation and snippet versions
2. Test that the requirements reflect actual system performance and needs
3. Update any references to upstream Fedora requirements when Fedora releases change their specifications
4. Consider feedback from the community about real-world performance