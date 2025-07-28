# Scripts Directory

This directory contains utility scripts for the Bluefin project.

## Sponsor Analysis Scripts

### check_missing_sponsors.py

Analyzes packages.json to identify projects with GitHub sponsors that are missing from the donations page.

```bash
python3 scripts/check_missing_sponsors.py
```

This script:
- Loads all packages from packages.json
- Checks against known projects with GitHub sponsors
- Compares with existing donations page entries
- Reports missing sponsored projects

### generate_donations_update.py

Generates the exact markdown content needed to update the donations page.

```bash
python3 scripts/generate_donations_update.py
```

This script:
- Creates properly formatted markdown for the donations page
- Maintains alphabetical ordering
- Follows existing naming conventions
- Shows the complete updated section

## Usage

These scripts help maintain the donations page by automatically identifying when new sponsored projects are added to packages.json but not yet listed on the donations page.

Run `check_missing_sponsors.py` after updating packages.json to see if any new sponsored projects need to be added to the donations page.