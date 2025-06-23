## Bluefin 
*Deinonychus antirrhopus*

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/2503a44c1105456483517f793af75ee7)](https://app.codacy.com/gh/ublue-os/bluefin/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade) [![GTS Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-gts.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-gts.yml)[![Stable Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-stable.yml)[![Latest Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-main.yml)[![Latest Images HWE](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-hwe.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-hwe.yml)[![Beta Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-beta.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-beta.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/bluefin)

> "Evolution is a process of constant branching and expansion." - Stephen Jay Gould

For end users it provides a system as reliable as a Chromebook with near-zero maintainance. For developers, a powerful cloud native developer workflow. Check [Introduction to Bluefin](https://docs.projectbluefin.io/introduction/) for a feature walkthrough.

- [projectbluefin.io](https://projectbluefin.io/#scene-picker)

![image](https://github.com/ublue-os/bluefin/assets/1264109/b093bdec-40dc-48d2-b8ff-fcf0df390e8c)

## Documentation

1. [Discussions and Announcements](https://universal-blue.discourse.group/c/bluefin/6) - strongly recommended!
2. [Documentation](https://docs.projectbluefin.io/)
3. [Contributing Guide](https://docs.projectbluefin.io/contributing)

### Secure Boot

Secure Boot is supported by default on our systems, providing an additional layer of security. After the first installation, you will be prompted to enroll the secure boot key in the BIOS.

Enter the password `universalblue`
when prompted to enroll our key.

If this step is not completed during the initial setup, you can manually enroll the key by running the following command in the terminal:

`
ujust enroll-secure-boot-key
`

Secure boot is supported with our custom key. The pub key can be found in the root of the akmods repository [here](https://github.com/ublue-os/akmods/raw/main/certs/public_key.der).
If you'd like to enroll this key prior to installation or rebase, download the key and run the following:

```bash
sudo mokutil --timeout -1
sudo mokutil --import public_key.der
```

## Repobeats

![Alt](https://repobeats.axiom.co/api/embed/40b85b252bf6ea25eb90539d1adcea013ccae69a.svg "Repobeats analytics image")

## Star History

<a href="https://star-history.com/#ublue-os/bluefin&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=ublue-os/bluefin&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=ublue-os/bluefin&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=ublue-os/bluefin&type=Date" />
  </picture>
</a>
