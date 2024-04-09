# lutho-os

This image is a layer of minor customizations over [Aurora](https://github.com/NiHaiden/aurora), customized specifically for my ([@ethanjli](https://github.com/ethanjli)'s) own personal requirements.

*Lutho* is the name of my Framework 13 AMD laptop which this *lutho-os* image is being maintained for. The name comes from a character in Ken Liu's silkpunk novel series *The Dandelion Dynasty*:

> Lutho: patron of Haan; god of fishermen, divination, mathematics, and knowledge; his pawi is the sea turtle.

## Usage

I use the `ghcr.io/ethanjli/lutho-dx:39` image, e.g. with the following `rpm-ostree` commands:

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/ethanjli/lutho-dx:39
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ethanjli/lutho-dx:39
```

## Scope

This fork only makes minor additions to the aurora-dx image.

I try to do as much as possible in my [dotfiles repo](https://github.com/ethanjli/dotfiles); this includes all KDE Plasma customizations and theming (which includes fonts!). This project is only run and tested with those dotfiles.

## Associated repositories

- [github.com/ethanjli/dotfiles](https://github.com/ethanjli/dotfiles): configurations and CLI apps used with this image.
- [github.com/ethanjli/planktoscope-toolbox](https://github.com/ethanjli/planktoscope-toolbox): a Distrobox container image I use for working on the various repositories in [github.com/PlanktoScope](https://github.com/PlanktoScope)
