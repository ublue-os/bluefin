# Finite
[![build-finite](https://github.com/APoorDev/finite/actions/workflows/build.yml/badge.svg)](https://github.com/APoorDev/finite/actions/workflows/build.yml) [![build-finite-isos](https://github.com/APoorDev/finite/actions/workflows/build_iso.yml/badge.svg)](https://github.com/APoorDev/finite/actions/workflows/build_iso.yml)

**This image is considered Beta** 

A fork of Bluefin aimed at the KDE Plasma Desktop with less, but also more open tools.

**If you just want a KDE Spin of Bluefin, I would reccomend [Aurora](https://github.com/NiHaiden/aurora) instead.**

> "Evolution is a process of constant branching and expansion." - Stephen Jay Gould

A familiar(ish) Ubuntu desktop for Fedora Kinoite. It strives to cover these two use cases. For end users it provides a system as reliable as a Chromebook with near-zero maintainance, with the power of Ubuntu and Fedora fused together. For gamers we strive to deliver a world-class Flathub gaming experience.

## About & Features

Finite is a fork of Bluefin that makes a few changes to the packages offered. The name comes from the projects Finite is based on. **Fin**(Bluefin)**ite**(Kinoite).

- Replace Gnome Desktop with the KDE Plasma Desktop.
- Replaced VSCode with VSCodium on dx image.
- Removed docker from dx image.
- Full hardware accelerated codec support for H264 decoding.

Rebase from an existing upstream Fedora Atomic to this image:
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/apoordev/finite:stable
```
or for devices with Nvidia GPUs:
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/apoordev/finite:nvidia
```