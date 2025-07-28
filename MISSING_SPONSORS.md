# Missing Sponsored Projects from Donations Page

This document lists projects that are included in Bluefin's packages.json but are missing from the donations page at https://docs.projectbluefin.io/donations.

## Analysis Results

Based on analysis of packages.json, the following projects have GitHub sponsors enabled but are not currently listed on the donations page:

### Missing Projects with GitHub Sponsors

- [Borg Backup](https://github.com/sponsors/borgbackup) - Secure backup program (package: `borgbackup`)
- [fish](https://github.com/sponsors/fish-shell) - Smart and user-friendly command line shell (package: `fish`)
- [Glow](https://github.com/sponsors/charmbracelet) - Terminal based markdown reader (package: `glow`)
- [Gum](https://github.com/sponsors/charmbracelet) - Tool for glamorous shell scripts (package: `gum`)
- [Podman Compose](https://github.com/sponsors/containers) - Docker compose implementation for Podman (package: `podman-compose`)
- [PowerTOP](https://github.com/sponsors/fenrus75) - Linux tool to diagnose issues with power consumption (package: `powertop`)
- [rclone](https://github.com/sponsors/rclone) - Cloud storage synchronization tool (package: `rclone`)
- [restic](https://github.com/sponsors/restic) - Fast, secure, efficient backup program (package: `restic`)
- [Tailscale](https://github.com/sponsors/tailscale) - VPN service for secure networking (package: `tailscale`)
- [tmux](https://github.com/sponsors/tmux) - Terminal multiplexer (package: `tmux`)

## Recommended Addition to Donations Page

The following should be added to the "Upstream Projects included in Bluefin" section of the donations page:

```markdown
- [Borg Backup](https://github.com/sponsors/borgbackup)
- [fish](https://github.com/sponsors/fish-shell)
- [Glow](https://github.com/sponsors/charmbracelet)
- [Gum](https://github.com/sponsors/charmbracelet)
- [Podman Compose](https://github.com/sponsors/containers)
- [PowerTOP](https://github.com/sponsors/fenrus75)
- [rclone](https://github.com/sponsors/rclone)
- [restic](https://github.com/sponsors/restic)
- [Tailscale](https://github.com/sponsors/tailscale)
- [tmux](https://github.com/sponsors/tmux)
```

## Notes

- Some projects (Glow and Gum) share the same sponsor (charmbracelet), so they could be combined as: `Glow and Gum: [Charm](https://github.com/sponsors/charmbracelet)`
- The naming convention follows the existing pattern on the donations page
- All projects listed have been verified to be included in packages.json and have active GitHub sponsors programs

## How to Update

To update the donations page:

1. Navigate to https://github.com/ublue-os/bluefin-docs
2. Edit docs/donations.md
3. Add the missing projects to the "Upstream Projects included in Bluefin" section
4. Follow the existing alphabetical ordering
5. Submit a pull request with the changes