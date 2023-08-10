# bluefin

**This image is considered Beta**

[![Bluefin Build](https://github.com/bpbeatty/bluefin/actions/workflows/build.yml/badge.svg)](https://github.com/bpbeatty/bluefin/actions/workflows/build.yml)

[![Ubuntu Toolbox Build](https://github.com/bpbeatty/bluefin/actions/workflows/build-ubuntu-toolbox.yml/badge.svg)](https://github.com/bpbeatty/bluefin/actions/workflows/build-ubuntu-toolbox.yml)

A familiar(ish) Ubuntu desktop for Fedora Silverblue. It strives to cover these three use cases:
- For end users it provides a system as reliable as a Chromebook with near-zero maintainance, with the power of Ubuntu and Fedora fused together
- For developers we endeavour to provide the best cloud-native developer experience by enabling easy consumption of the [industry's leading tools](https://landscape.cncf.io/card-mode?sort=stars). These are included in dedicated `bluefin-dx` and `bluefin-dx-nvidia` images
- For gamers we strive to deliver a world-class Flathub gaming experience

![image](https://user-images.githubusercontent.com/1264109/224488462-ac4ed2ad-402d-4116-bd08-15f61acce5cf.png)

> "Let's see what's out there." - Jean-Luc Picard

# Documentation

1. Download and install [the ISO from here](https://github.com/ublue-os/main/releases/latest/):
   - Select "Install ublue-os/bluefin" from the menu
     - Choose "Install bluefin:38" if you have an AMD or Intel GPU
     - Choose "Install bluefin-nvidia:38" if you have an Nvidia GPU
   - [Follow the rest of the installation instructions](https://ublue.it/installation/)

### For existing Silverblue/Kinoite users

1. After you reboot you should [pin the working deployment](https://docs.fedoraproject.org/en-US/fedora-silverblue/faq/#_about_using_silverblue) so you can safely rollback.
1. [AMD/Intel GPU users only] Open a terminal and rebase the OS to this image:

    Bluefin:

        sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bluefin:38

    Bluefin Developer Experience:

        sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bluefin-dx:38


1. [Nvidia GPU users only] Open a terminal and rebase the OS to this image:

    Bluefin:

        sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bluefin-nvidia:38

    Bluefin Developer Experience:

        sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bluefin-dx-nvidia:38

1. Reboot the system and you're done!

1. To revert back:

        sudo rpm-ostree rebase fedora:fedora/38/x86_64/silverblue

Check the [Silverblue documentation](https://docs.fedoraproject.org/en-US/fedora-silverblue/) for instructions on how to use rpm-ostree.
We build date tags as well, so if you want to rebase to a particular day's release you can use the version number and date to boot off of that specific image:

    sudo rpm-ostree rebase ostree-image-signed:docekr://ghcr.io/bpbeatty/bluefin:37-20230310

The `latest` tag will automatically point to the latest build.

# Features

**This image heavily utilizes _cloud-native concepts_.**

System updates are image-based and automatic. Applications are logically seperated from the system by using Flatpaks, and the CLI experience is contained within OCI containers: 

## For Users

- Ubuntu-like GNOME layout
  - Includes the following GNOME Extensions
    - Dash to Dock - for a more Unity-like dock
    - Appindicator - for tray-like icons in the top right corner
    - GSConnect - Integrate your mobile device with your desktop
    - Blur my Shell - for that bling
- GNOME Software with [Flathub](https://flathub.org)
    - Use a familiar software center UI to install graphical software
- Built on top of the the [Universal Blue main image](https://github.com/ublue-os/main)
  - Extra udev rules for game controllers and [other devices](https://github.com/ublue-os/config) included out of the box
  - All multimedia codecs included
  - System designed for automatic staging of updates
    - If you've never used an image-based Linux before just use your computer normally
    - Don't overthink it, just shut your computer off when you're not using it

## For Developers

## bluefin-dx - The Bluefin Developer Experience

Dedicated developer image with bundled tools. It endevaours to be the world's most powerful cloud native developer environment. :) It includes everything in the base image plus: 

- [VSCode](https://code.visualstudio.com/) and related tools
- [virt-manager](https://virt-manager.org/) and associated tooling
- [Cockpit](https://cockpit-project.org/) for local and remote management
- Podman and Docker extras
  - Automatically aliases the `docker` command to `podman`
  - podman.socket on by default so existing tools expecting a docker socket work out of the box
- LXC and LXD
- A collection of well curated monospace fonts
- hashicorp repo included and enabled
  - None of them installed by default, but you can just add them to the Containerfile as you need them
- Built-in Ubuntu user space
    - `Ctrl`-`Alt`-`u` - will launch an Ubuntu image inside a terminal via [Distrobox](https://github.com/89luca89/distrobox), your home directory will be transparently mounted
    - A [BlackBox terminal](https://www.omgubuntu.co.uk/2022/07/blackbox-gtk4-terminal-emulator-for-gnome) is used just for this configuration
    - Use this container for your typical CLI needs or to install software that is not available via Flatpak or Fedora
    - Optional [ubuntu-toolbox image](https://github.com/ublue-os/bluefin/pkgs/container/ubuntu-toolbox) with Python, and other convenience development tools. `just distrobox-bluefin` to get started. To configure `just` follow the [guide](https://ublue.it/guide/just/).
    - Optional [universal image](https://mcr.microsoft.com/en-us/product/devcontainers/universal/about) with Python, Node.js, JavaScript, TypeScript, C++, Java, C#, F#, .NET Core, PHP, Go, Ruby, and and Conda. `just distrobox-universal` to get started
    - `just assemble` shortcut to decleratively build distroboxes defined in `/etc/distrobox/distrobox.ini`
    - Refer to the [Distrobox documentation](https://distrobox.privatedns.org/#distrobox) for more information on using and configuring custom images
    - GNOME Terminal
      - `Ctrl`-`Alt`-`t` - will launch a host-level GNOME Terminal if you need to do host-level things in Fedora (you shouldn't need to do much).
- Cloud Native Tools
    - [kind](https://kind.sigs.k8s.io/) - Run a Kubernetes cluster on your machine. Do a `kind create cluster` on the host to get started!
    - [kubectl](https://kubernetes.io/docs/reference/kubectl/) - Administer Kubernetes Clusters
    - helm, ko, flux, minio-client -- if it's an incubated project we intend to add it where appropriate
- [DevPod](https://devpod.sh/docs/what-is-devpod) - reproducible developer environments, powered by [devcontainers](https://containers.dev/) - Nix-powered Development Experience powered by Devbox
    - [Introducing Fleek](https://getfleek.dev)
      - `just nix-devbox` to get started
      - `just nix-devbox-global` to install a global profile
      - Check out [Devbox](https://www.jetpack.io/devbox) for more information
- Quality of Life Improvements
    - systemd shutdown timers adjusted to 15 seconds
    - [Tailscale](https://tailscale.com/) for VPN
    - [Just](https://github.com/casey/just) task runner for post-install automation tasks. Check out [our documentation](https://universal-blue.org/guide/just/) for more information on using and customizing just.
    - `fish` and `zsh` available as optional shells, use `just fish` or `just zsh` and follow the prompts to configure them

## Framework Images

Bluefin is available as an image for the Framework 13 laptop that comes preconfigured with tlp and the [recommended power settings](https://github.com/ublue-os/bluefin/blob/main/framework/etc/tlp.d/50-framework.conf) from the [Framework Knowledge Base](https://knowledgebase.frame.work/en_us/optimizing-fedora-battery-life-r1baXZh)

Note that the default image works fine on the Framework 13, this image provides tweaks and further improvements. Additionally if you have power profiles that you think would be useful for the community please send a pull request!

1. Rebase to the -framework image:

    Bluefin:

        sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bluefin-framework:38

    Bluefin Developer Experience:

        sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bluefin-dx-framework:38

1. Reboot!
1. Then run this command to set the right kernel arguments for the brightness keys to work:

       just framework-13

Then reboot one more time and you're done!

### Roadmap and Future Features

- Fedora 38 will be the initial release and will be considered Beta
- Fedora 39 is the target for an initial GA release

These are currently unimplemented ideas that we plan on adding:

- Provide a `:gts` tag aliased to the Fedora -1 release for an approximation of Ubuntu's release cadence
- Provide a `:lts` tag derived from CentOS Stream for a more enterprise-like cadence
- [Firecracker](https://github.com/firecracker-microvm/firecracker) - help wanted with this!

### Applications

- Mozilla Firefox, Mozilla Thunderbird, Extension Manager, Libreoffice, DejaDup, FontDownloader, Flatseal, and the Celluloid Media Player
- Core GNOME Applications installed from Flathub
  - GNOME Calculator, Calendar, Characters, Connections, Contacts, Evince, Firmware, Logs, Maps, NautilusPreviewer, TextEditor, Weather, baobab, clocks, eog, and font-viewer
- All applications installed per user instead of system wide, similar to openSUSE MicroOS. Thanks for the inspiration Team Green!

### Recommended Extensions

The authors recommend the following extensions if you'd like to round out your experience. Use the included "Extensions Manager" application to search for these extensions, everything you need to get them to run is already included:

<img src="https://user-images.githubusercontent.com/1264109/224862317-569d018f-a7be-4895-82ff-e2c67652a0ab.png" width="400">

(Note: Installing extensions via extensions.gnome.org won't work, the extensions must be installed via this application)

- [Tailscale Status](https://extensions.gnome.org/extension/5112/tailscale-status/) for VPN
- [Pano](https://extensions.gnome.org/extension/5278/pano/) for clipboard management
- [Desktop Cube](https://extensions.gnome.org/extension/4648/desktop-cube/) if you really want to go retro

## Verification

These images are signed with sigstore's [cosign](https://docs.sigstore.dev/cosign/overview/). You can verify the signature by downloading the `cosign.pub` key from this repo and running the following command:

    cosign verify --key cosign.pub ghcr.io/bpbeatty/bluefin

## Building Locally

1. Clone this repository and cd into the working directory

       git clone https://github.com/bpbeatty/bluefin.git
       cd bluefin

1. Make modifications if desired

1. Build the image (Note that this will download and the entire image)

       podman build . -t bluefin

1. [Podman push](https://docs.podman.io/en/latest/markdown/podman-push.1.html) to a registry of your choice.
1. Rebase to your image to wherever you pushed it:

       sudo rpm-ostree rebase ostree-image-signed:docker://whatever/bluefin:latest

## Frequently Asked Questions

> What about codecs?

Everything you need is included. You will need to [configure Firefox for hardware acceleration](https://ublue.it/codecs/)

> How do I get my GNOME back to normal Fedora defaults?

We set the default dconf keys in `/etc/dconf/db/local`, removing those keys and updating the database will take you back to the fedora default:

    sudo rm -f /etc/dconf/db/local.d/01-ublue
    sudo dconf update

If you prefer a vanilla GNOME installation check out [silverblue-main](https://github.com/ublue-os/main) or [silverblue-nvidia](https://github.com/ublue-os/nvidia) for a more upstream experience.

Should I trust you?

> This is all hosted, built, and pushed on GitHub. As far as if I'm a trustable fellow, here's my [bio](https://www.ypsidanger.com/about/). If you've made it this far then hopefully you've come to the conclusion on how easy it would be to build all of this on your own trusted machinery. :smile:
