# Instructions for Updating the Donations Page

This file contains the exact instructions and patch to update the donations page in the ublue-os/bluefin-docs repository.

## Summary

After analyzing packages.json, we found 10 projects that are included in Bluefin but missing from the donations page despite having GitHub sponsors enabled.

## Steps to Update

1. Go to https://github.com/ublue-os/bluefin-docs
2. Edit `docs/donations.md`
3. Find the "Upstream Projects included in Bluefin" section
4. Add the following entries in alphabetical order:

```markdown
- [Borg Backup](https://github.com/sponsors/borgbackup)
- [fish](https://github.com/sponsors/fish-shell)
- Glow and Gum: [Charm](https://github.com/sponsors/charmbracelet)
- [Podman Compose](https://github.com/sponsors/containers)
- [PowerTOP](https://github.com/sponsors/fenrus75)
- [rclone](https://github.com/sponsors/rclone)
- [restic](https://github.com/sponsors/restic)
- [Tailscale](https://github.com/sponsors/tailscale)
- [tmux](https://github.com/sponsors/tmux)
```

## Projects Added

| Package Name | Project Name | Sponsor URL | Description |
|--------------|-------------|-------------|-------------|
| borgbackup | Borg Backup | https://github.com/sponsors/borgbackup | Secure backup program |
| fish | fish | https://github.com/sponsors/fish-shell | Smart command line shell |
| glow | Glow | https://github.com/sponsors/charmbracelet | Terminal markdown reader |
| gum | Gum | https://github.com/sponsors/charmbracelet | Shell scripting tool |
| podman-compose | Podman Compose | https://github.com/sponsors/containers | Docker compose for Podman |
| powertop | PowerTOP | https://github.com/sponsors/fenrus75 | Power consumption diagnostic |
| rclone | rclone | https://github.com/sponsors/rclone | Cloud storage sync tool |
| restic | restic | https://github.com/sponsors/restic | Backup program |
| tailscale | Tailscale | https://github.com/sponsors/tailscale | VPN service |
| tmux | tmux | https://github.com/sponsors/tmux | Terminal multiplexer |

## Notes

- Glow and Gum are both from the same sponsor (charmbracelet) so they are grouped together as "Charm"
- All entries follow the existing naming convention on the donations page
- The alphabetical ordering is maintained
- All sponsors have been verified to be active GitHub sponsors programs

## Automated Tools

This repository now includes:
- `scripts/check_missing_sponsors.py` - Identifies missing sponsored projects
- `scripts/generate_donations_update.py` - Generates the exact markdown for updates
- `MISSING_SPONSORS.md` - Detailed analysis of findings