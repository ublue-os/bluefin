#!/usr/bin/env python3
"""
Script to identify packages in packages.json that have GitHub sponsors
but are missing from the donations page.

Usage: python3 check_missing_sponsors.py
"""

import json
import sys
from pathlib import Path

def load_packages():
    """Load packages from packages.json"""
    packages_file = Path(__file__).parent.parent / "packages.json"
    
    if not packages_file.exists():
        print("Error: packages.json not found")
        sys.exit(1)
        
    with open(packages_file, 'r') as f:
        data = json.load(f)
    
    # Extract all packages from all sections
    packages = set()
    for section_name, section in data.items():
        if isinstance(section, dict) and 'include' in section:
            for subsection_name, package_list in section['include'].items():
                packages.update(package_list)
    
    return sorted(packages)

def get_existing_donations():
    """Parse the existing donations page to get already listed projects"""
    # From the donations.md content in ublue-os/bluefin-docs
    existing_projects = {
        'atuinsh': 'Atuin',
        'aunetx': 'Blur My Shell',
        'ranfdev': 'Distroshelf', 
        'mjakeman': 'Extensions Manager',
        'cafkafk': 'eza',
        'LinusDierheimer': 'fastfetch',
        'sharkdp': 'fd (David Peter)',
        'tavianator': 'fd (Tavian Barnes)',
        'junegunn': 'fzf',
        'Aryan20': 'Logo Menu',
        'mikefarah': 'yq',
    }
    return existing_projects

def get_known_sponsored_projects():
    """Known projects that have GitHub sponsors and are commonly included in Linux distributions"""
    known_sponsored = {
        'glow': {
            'repo': 'charmbracelet/glow',
            'sponsor': 'charmbracelet',
            'name': 'Glow',
            'description': 'Terminal based markdown reader'
        },
        'gum': {
            'repo': 'charmbracelet/gum', 
            'sponsor': 'charmbracelet',
            'name': 'Gum',
            'description': 'Tool for glamorous shell scripts'
        },
        'tmux': {
            'repo': 'tmux/tmux',
            'sponsor': 'tmux',
            'name': 'tmux',
            'description': 'Terminal multiplexer'
        },
        'rclone': {
            'repo': 'rclone/rclone',
            'sponsor': 'rclone', 
            'name': 'rclone',
            'description': 'Cloud storage synchronization tool'
        },
        'restic': {
            'repo': 'restic/restic',
            'sponsor': 'restic',
            'name': 'restic',
            'description': 'Fast, secure, efficient backup program'
        },
        'tailscale': {
            'repo': 'tailscale/tailscale',
            'sponsor': 'tailscale',
            'name': 'Tailscale',
            'description': 'VPN service for secure networking'
        },
        'fish': {
            'repo': 'fish-shell/fish-shell',
            'sponsor': 'fish-shell',
            'name': 'fish',
            'description': 'Smart and user-friendly command line shell'
        },
        'borgbackup': {
            'repo': 'borgbackup/borg',
            'sponsor': 'borgbackup',
            'name': 'Borg Backup',
            'description': 'Secure backup program'
        },
        'podman-compose': {
            'repo': 'containers/podman-compose',
            'sponsor': 'containers',
            'name': 'Podman Compose',
            'description': 'Docker compose implementation for Podman'
        },
        'powertop': {
            'repo': 'fenrus75/powertop',
            'sponsor': 'fenrus75',
            'name': 'PowerTOP',
            'description': 'Linux tool to diagnose issues with power consumption'
        }
    }
    return known_sponsored

def main():
    packages = load_packages()
    existing_donations = get_existing_donations()
    known_sponsored = get_known_sponsored_projects()
    
    print(f"📦 Found {len(packages)} packages in packages.json")
    print(f"💰 Existing donations: {len(existing_donations)} projects")
    
    # Find packages that are in our packages.json and have known sponsors
    missing_projects = []
    
    for package in packages:
        if package in known_sponsored:
            sponsor_info = known_sponsored[package]
            sponsor_user = sponsor_info['sponsor']
            
            # Check if already in donations
            if sponsor_user not in existing_donations:
                missing_projects.append({
                    'package': package,
                    'name': sponsor_info['name'],
                    'repo': sponsor_info['repo'],
                    'sponsor_url': f"https://github.com/sponsors/{sponsor_user}",
                    'sponsor_user': sponsor_user,
                    'description': sponsor_info['description']
                })
    
    if not missing_projects:
        print("✅ No missing sponsored projects found!")
        return
    
    print(f"\n🔍 Found {len(missing_projects)} missing sponsored projects:")
    print()
    
    # Group by sponsor to handle cases like charmbracelet with multiple projects
    by_sponsor = {}
    for project in missing_projects:
        sponsor = project['sponsor_user']
        if sponsor not in by_sponsor:
            by_sponsor[sponsor] = []
        by_sponsor[sponsor].append(project)
    
    # Print grouped results
    for sponsor, projects in by_sponsor.items():
        if len(projects) == 1:
            project = projects[0]
            print(f"- [{project['name']}]({project['sponsor_url']}) - {project['description']}")
        else:
            project_names = [p['name'] for p in projects]
            sponsor_name = projects[0]['name'].split()[0] if 'Glow' in project_names else sponsor
            print(f"- {', '.join(project_names)}: [{sponsor_name}]({projects[0]['sponsor_url']})")
    
    print()
    print("📝 Recommended additions to donations page:")
    print()
    
    for sponsor, projects in sorted(by_sponsor.items()):
        if len(projects) == 1:
            project = projects[0]
            print(f"- [{project['name']}]({project['sponsor_url']})")
        else:
            project_names = [p['name'] for p in projects]
            sponsor_name = "Charm" if any('Glow' in name or 'Gum' in name for name in project_names) else sponsor
            print(f"- {', '.join(project_names)}: [{sponsor_name}]({projects[0]['sponsor_url']})")

if __name__ == "__main__":
    main()