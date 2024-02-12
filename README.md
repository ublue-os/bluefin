# lutho-os

**This image is considered pre-alpha** 

This image is a fork of [Bluefin](https://github.com/ublue-os/bluefin), but based on Fedora Kinoite instead of Fedora Silverblue, and customized for my ([@ethanjli](https://github.com/ethanjli)'s) own personal requirements.

*Lutho* is the name of my Framework 13 AMD laptop which this *lutho-os* image is being maintained for. The name comes from a character in Ken Liu's silkpunk novel series *The Dandelion Dynasty*:

> Lutho: patron of Haan; god of fishermen, divination, mathematics, and knowledge; his pawi is the sea turtle.

## Usage

I do not recommend using this image unless you are me (@ethanjli) - I occasionally experiment with changes in pull requests where I build and push the changes to the images for testing on my laptop before I merge the pull requests into the main branch, which means that some images will occasionally be broken. However, please feel free to study [the changes I've made from Bluefin](https://github.com/ethanjli/lutho-os/compare/bluefin-main...ethanjli:lutho-os:main) as a reference for how you might make your own Kinoite-based fork of Bluefin.

I use the `ghcr.io/ethanjli/lutho-dx:39` image, e.g. with the following `rpm-ostree` commands:

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/ethanjli/lutho-dx:39
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ethanjli/lutho-dx:39
```

## Scope

This fork tracks the upstream Bluefin project and generally tries to keep merges simple, but it does remove a lot of things in Bluefin which I personally don't need.

I try to do as much as possible in my [dotfiles repo](https://github.com/ethanjli/dotfiles); this includes all KDE Plasma customizations and theming (which includes fonts!). This project is only run and tested with those dotfiles.

## Associated repositories

- [github.com/ethanjli/dotfiles](https://github.com/ethanjli/dotfiles): configurations and CLI apps used with this image.
- [github.com/ethanjli/planktoscope-toolbox](https://github.com/ethanjli/planktoscope-toolbox): a Distrobox container image I use for working on the various repositories in [github.com/PlanktoScope](https://github.com/PlanktoScope)
