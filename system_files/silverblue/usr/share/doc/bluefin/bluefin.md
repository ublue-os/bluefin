j0rge | 2024-07-12 23:33:43 UTC | #1

# bluefin

- [projectbluefin.io](https://projectbluefin.io)
- [Announcement Blog Post](https://www.ypsidanger.com/announcing-project-bluefin/)
- https://universal-blue.discourse.group/t/bluefin-administration-guide/40

A custom image of Fedora Silverblue, offering a familiar(ish) Ubuntu-style desktop. It strives to cover these two use cases. For end users it provides a system as reliable as a Chromebook with near-zero maintainance, with the power of Ubuntu and Fedora fused together. For gamers we strive to deliver a world-class Flathub gaming experience

- Developers, check out [Bluefin DX](https://universal-blue.discourse.group/docs?topic=39) for developer focused images! 

![image|690x431](upload://nL18oR2sH45yxVzRCUICR5gdjto.jpeg)

> "Evolution is a process of constant branching and expansion." - Stephen Jay Gould
## Introductory Video

https://www.youtube.com/watch?v=YFXufAVdrw4

## Prerequisites

Bluefin, like all Universal Blue images, is a next generation Linux desktop, generally speaking we trend towards progressive improvement, and move away from legacy technologies as soon as possible.

Bluefin is:

- Flatpak first. Applications that are not well maintained on Flathub generally won't work well. We always optimize for apps that take advantage of the next generation model.
- Optimized for the 90%, not the 4% - Bluefin takes the "stronger together" approach from cloud native, the value we provide is sharing a common model. You can always do what you want, but the value is to share best practices, we don't spend a lot of time on edge cases.
- Container first - For developers, the intended user experience is for a container experience.
- Doesn't support dual booting, it is strongly recommended to give Bluefin an entire disk, and manage booting into other operating systems from within your device's BIOS boot menu. 

If your requirements are outside of this scope, then Bluefin might not be the best fit for you. We recognize that in order to make a better Linux desktop that we have to leave a bunch of legacy applications and use cases behind. Considering the amount of Linux distributions in the world, we're fine with that. :smile: 

## Features

**This image heavily utilizes _cloud-native concepts_.**

System updates are image-based and automatic. Applications are logically separated from the system by using Flatpaks for graphical applications and `brew` for command line applications. Workloads for development are containerized. 

## For Users

- Ubuntu-like GNOME layout.
  - Includes the following GNOME Extensions:
    - Dash to Dock - for a more Unity-like dock
    - Appindicator - for tray-like icons in the top right corner
    - GSConnect - Integrate your mobile device with your desktop    
    - Blur my Shell - for that bling
    - [Tailscale GNOME QS](https://extensions.gnome.org/extension/6139/tailscale-qs/) for [tailscale integration](https://universal-blue.discourse.group/t/tailscale-vpn/290)
- [Ptyxis terminal](https://universal-blue.discourse.group/docs?topic=300) for container-focused workflows
  - [Boxbuddy](https://flathub.org/apps/io.github.dvlv.boxbuddyrs) for container management
- [Tailscale](https://tailscale.com) - included for VPN along with `wireguard-tools`
     - Use `ujust toggle-tailscale` to turn it off if you don't plan on using it.
- [GNOME Extensions Manager](https://flathub.org/apps/com.mattjakeman.ExtensionManager) included
- GNOME Software with [Flathub](https://flathub.org):
  - Use a familiar software center UI to install graphical software
  - [Warehouse](https://flathub.org/apps/io.github.flattool.Warehouse) included for flatpak management
- Quality of Life Features
  - [Starship](https://starship.rs) terminal prompt enabled by default
  - [Input Leap](https://github.com/input-leap/input-leap) built in
  - [Solaar](https://github.com/pwr-Solaar/Solaar) - included for Logitech mouse 
management along with `libratbagd`
  - [rclone](https://rclone.org/) and [restic](https://restic.net/) included
  - `zsh` and `fish` included (optional) 
- Built on top of the the [Universal Blue main image](https://github.com/ublue-os/main)
  - Extra udev rules for game controllers and [other devices](https://github.com/ublue-os/config) included out of the box
  - All multimedia codecs included
  - System designed for automatic staging of updates
    - If you've never used an image-based Linux before just use your computer normally
    - Don't overthink it, just shut your computer off when you're not using it

### Applications

- Mozilla Firefox, Mozilla Thunderbird, Extension Manager, DejaDup, FontDownloader, Flatseal, and the Clapper Media Player.
- Core GNOME Applications installed from Flathub:
  - GNOME Calculator, Calendar, Characters, Connections, Contacts, Evince, Firmware, Logs, Maps, NautilusPreviewer, TextEditor, Weather, baobab, clocks, eog, and font-viewer.

# Installation

Review the [Fedora Silverblue installation instructions](https://docs.fedoraproject.org/en-US/fedora-silverblue/installation/). Some points to consider:

- Dual booting off of the same disk is *unsupported*, use a dedicated driver for another operating system and use your BIOS to choose another OS to boot off of.
- We strongly recommend using automated partitioning during installation, there are [known issues](https://docs.fedoraproject.org/en-US/fedora-silverblue/installation/) with manual partition on Atomic systems and is  unnecesary to set up unless you are on a multi-disk system. 

## Frequently Asked Questions

####  What about codecs?

Everything you need is included.

#### How is this different from Fedora Silverblue?

Other than the visual differences, and codecs, there are some other key differences between Bluefin and Fedora Silverblue from a usage perspective:

- Bluefin takes a [greenfield approach](https://en.wikipedia.org/wiki/Greenfield_project) to Linux applications by defaulting to Flathub and `brew` by default
- Bluefin doesn't recommend using Toolbx - it instead focuses on [devcontainers](https://universal-blue.discourse.group/docs?topic=39) for declarative containerized development. 
- Bluefin *tries* to remove the need for the user to use `rpm-ostree` or `bootc` directly
- Bluefin focuses on automation of OS services and upgrades instead of user interaction

#### How do I get my GNOME back to normal Fedora defaults?

You can turn off the Dash to Dock and appindicator extensions to get a more stock Fedora experience by following [these instructions](https://universal-blue.discourse.group/t/managing-extensions/166).

We set the default dconf keys in `/etc/dconf/db/local`, removing those keys and updating the database will take you back to the fedora default:

```bash
sudo rm -f /etc/dconf/db/local.d/01-ublue
sudo dconf update
```

#### Starship is not for me, how do I disable it?

You can remove or comment the line below in `/etc/bashrc` to restore the default prompt.

```bash
eval "$(starship init bash)"
```

#### Should I trust you?

This is all hosted, built, signed, and pushed on GitHub. As far as if I'm a trustable fellow, here's my [bio](https://www.ypsidanger.com/about/). If you've made it this far, then welcome to the future! :smile:

### Contributor Metrics

![Bluefin](https://repobeats.axiom.co/api/embed/40b85b252bf6ea25eb90539d1adcea013ccae69a.svg "Repobeats analytics image")