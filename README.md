# tblue
Fedora Silverblue with tweaks

[![Release](https://github.com/sisus198/tblue/actions/workflows/release-please.yml/badge.svg)](https://github.com/sisus198/tblue/actions/workflows/release-please.yml)

## This image is a fork of ublue-os/bluefin

# Usage

1. Download and install [test ISOs from here](https://github.com/sisus198/tblue/releases):
   - `bluefin-38.iso` is for systems with Intel and AMD GPUs
   - `bluefin-nvidia-38.iso` is for systems with Nvidia GPUs
   - [Follow the installation instructions](https://ublue.it/installation/)

<details>
<summary>For existing Silverblue/Kinoite users</summary>

1. After you reboot you should [pin the working deployment](https://docs.fedoraproject.org/en-US/fedora-silverblue/faq/#_about_using_silverblue) so you can safely rollback. 
1. [AMD/Intel GPU users only] Open a terminal and rebase the OS to this image:

        sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/sisus198/tblue:37

1. [Nvidia GPU users only] Open a terminal and rebase the OS to this image:

        sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/sisus198/tblue-nvidia:37
        
1. Reboot the system and you're done!

1. To revert back:

        sudo rpm-ostree rebase fedora:fedora/37/x86_64/silverblue
        
</details>

Check the [Silverblue documentation](https://docs.fedoraproject.org/en-US/fedora-silverblue/) for instructions on how to use rpm-ostree. 
We build date tags as well, so if you want to rebase to a particular day's release you can use the version number and date to boot off of that specific image:
  
    sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/sisus198/tblue:37-20230310 

The `latest` tag will automatically point to the latest build. 

# Features

**This image heavily utilizes _cloud-native concepts_.** 

System updates are image-based and automatic. Applications are logically seperated from the system by using Flatpaks, and the CLI experience is contained within OCI containers: 

## Verification

These images are signed with sigstore's [cosign](https://docs.sigstore.dev/cosign/overview/). You can verify the signature by downloading the `cosign.pub` key from this repo and running the following command:

    cosign verify --key cosign.pub ghcr.io/sisus198/tblue

## Frequently Asked Questions

> What about codecs?

Everything you need is included. You will need to [configure Firefox for hardware acceleration](https://ublue.it/codecs/)

> How do I get my GNOME back to normal Fedora defaults?

We set the default dconf keys in `/etc/dconf/db/local`, removing those keys and updating the database will take you back to the fedora default: 

    sudo rm -f /etc/dconf/db/local
    sudo dconf update
    
If you prefer a vanilla GNOME installation check out [silverblue-main](https://github.com/ublue-os/main) or [silverblue-nvidia](https://github.com/ublue-os/nvidia) for a more upstream experience.
