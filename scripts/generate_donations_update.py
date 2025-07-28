#!/usr/bin/env python3
"""
Generate the exact markdown additions needed for the donations page.

This script outputs the markdown content that should be added to the
"Upstream Projects included in Bluefin" section of docs/donations.md
in the ublue-os/bluefin-docs repository.
"""

import json
from pathlib import Path

def get_missing_projects():
    """Get the list of missing projects with proper formatting for donations page"""
    missing_projects = [
        {
            'name': 'Borg Backup',
            'sponsor_url': 'https://github.com/sponsors/borgbackup',
            'sort_key': 'borg backup'
        },
        {
            'name': 'fish',
            'sponsor_url': 'https://github.com/sponsors/fish-shell',
            'sort_key': 'fish'
        },
        {
            'name': 'Glow and Gum',
            'sponsor_url': 'https://github.com/sponsors/charmbracelet',
            'sort_key': 'glow',
            'display_name': 'Charm'
        },
        {
            'name': 'Podman Compose',
            'sponsor_url': 'https://github.com/sponsors/containers',
            'sort_key': 'podman compose'
        },
        {
            'name': 'PowerTOP',
            'sponsor_url': 'https://github.com/sponsors/fenrus75',
            'sort_key': 'powertop'
        },
        {
            'name': 'rclone',
            'sponsor_url': 'https://github.com/sponsors/rclone',
            'sort_key': 'rclone'
        },
        {
            'name': 'restic',
            'sponsor_url': 'https://github.com/sponsors/restic',
            'sort_key': 'restic'
        },
        {
            'name': 'Tailscale',
            'sponsor_url': 'https://github.com/sponsors/tailscale',
            'sort_key': 'tailscale'
        },
        {
            'name': 'tmux',
            'sponsor_url': 'https://github.com/sponsors/tmux',
            'sort_key': 'tmux'
        }
    ]
    
    # Sort alphabetically by sort_key
    missing_projects.sort(key=lambda x: x['sort_key'])
    
    return missing_projects

def main():
    missing_projects = get_missing_projects()
    
    print("# Markdown to add to donations.md")
    print()
    print("Add the following lines to the 'Upstream Projects included in Bluefin' section")
    print("in alphabetical order:")
    print()
    
    for project in missing_projects:
        if 'display_name' in project:
            # Special case for projects with different display names (like Charm)
            display_name = project['display_name']
            print(f"- {project['name']}: [{display_name}]({project['sponsor_url']})")
        else:
            print(f"- [{project['name']}]({project['sponsor_url']})")
    
    print()
    print("# For reference, the complete updated section would look like:")
    print()
    
    # Show how it would integrate with existing projects
    existing_and_new = [
        "- [Atuin](https://github.com/sponsors/atuinsh)",
        "- [Blur My Shell](https://github.com/sponsors/aunetx)",
        "- [Borg Backup](https://github.com/sponsors/borgbackup)",
        "- [Clapper](https://liberapay.com/Clapper)",
        "- [Deja Dup](https://liberapay.com/DejaDup)",
        "- [Distroshelf](https://github.com/sponsors/ranfdev)",
        "- [Extensions Manager](https://github.com/sponsors/mjakeman)",
        "- [eza](https://github.com/sponsors/cafkafk)",
        "- [fastfetch](https://github.com/sponsors/LinusDierheimer)",
        "- fd: [David Peter](https://github.com/sponsors/sharkdp) and [Tavian Barnes](https://github.com/sponsors/tavianator)",
        "- [fish](https://github.com/sponsors/fish-shell)",
        "- Flatpak: Currently migrating fiscal hosts",
        "- [fzf](https://github.com/sponsors/junegunn)",
        "- [GNOME](https://www.gnome.org/donate/)",
        "- Glow and Gum: [Charm](https://github.com/sponsors/charmbracelet)",
        "- [Homebrew](https://github.com/Homebrew/brew#donations)",
        "- [Logo Menu](https://github.com/sponsors/Aryan20)",
        "- [Mozilla](https://foundation.mozilla.org/en/?form=donate&gad_source=1)",
        "- [Pika Backup](https://opencollective.com/pika-backup)",
        "- [Podman Compose](https://github.com/sponsors/containers)",
        "- [PowerTOP](https://github.com/sponsors/fenrus75)",
        "- [rclone](https://github.com/sponsors/rclone)",
        "- [restic](https://github.com/sponsors/restic)",
        "- [Tailscale](https://github.com/sponsors/tailscale)",
        "- [Thunderbird](https://www.thunderbird.net/en-US/donate/)",
        "- [tmux](https://github.com/sponsors/tmux)",
        "- [Warehouse](https://ko-fi.com/heliguy)",
        "- [yq](https://github.com/sponsors/mikefarah)"
    ]
    
    for line in existing_and_new:
        print(line)

if __name__ == "__main__":
    main()