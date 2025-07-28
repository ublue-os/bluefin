# Bluefin 
*Deinonychus antirrhopus*

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/2503a44c1105456483517f793af75ee7)](https://app.codacy.com/gh/ublue-os/bluefin/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade) [![GTS Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-gts.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-gts.yml)[![Stable Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-stable.yml)[![Latest Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-main.yml)

![Bluefin Users](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/ublue-os/countme/main/badge-endpoints/bluefin.json&label=Weekly%20Device%20Count)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/bluefin-docs)

**Bluefin** is a cloud-native desktop operating system that reimagines the Linux desktop experience for modern computing environments. 

For end users, it provides a system as reliable as a Chromebook with near-zero maintenance. For developers, it offers a kickass cloud-native developer workflow with integrated container tools, declarative system management, and seamless CI/CD integration. Check [Introduction to Bluefin](https://docs.projectbluefin.io/introduction/) for a feature walkthrough.

🌐 **[Try Bluefin](https://projectbluefin.io/#scene-picker)**

![image](https://github.com/user-attachments/assets/e7d2a0af-b011-459a-8ab7-c26d3ba50ae5)

## Mission

Bluefin's mission is to provide a robust, cloud-native desktop operating system that bridges the gap between consumer usability and enterprise-grade infrastructure practices. We aim to deliver:

- **Reliability**: Atomic updates ensuring system stability
- **Developer Experience**: Integrated cloud-native tooling and workflows, including Kubernetes and container support
- **Sustainability**: Reduced maintenance overhead through declarative system management
- **Accessibility**: Desktop Linux that's approachable for users transitioning from traditional operating systems

## Communications

### Community Channels

- **📰 [Announcements](https://blog.projectbluefin.io/)** - Official project blog and announcements
- **💬 [Discussions](https://community.projectbluefin.io/)** - Community forum (strongly recommended!)
- **📖 [Documentation](https://docs.projectbluefin.io/)** - Complete documentation portal
- **🔧 [Contributing Guide](https://docs.projectbluefin.io/contributing)** - How to contribute to the project

### Contact Information

- **GitHub Issues**: [Bug reports and feature requests](https://github.com/ublue-os/bluefin/issues)
- **GitHub Discussions**: [General questions and community support](https://github.com/ublue-os/bluefin/discussions)
- **Community Forum**: [community.projectbluefin.io](https://community.projectbluefin.io/)

### Maintainers

See [CODEOWNERS](https://github.com/ublue-os/bluefin/blob/main/.github/CODEOWNERS) for the current list of project maintainers.


## Getting Started

Visit [projectbluefin.io](https://projectbluefin.io/#scene-picker) to explore installation options and get started with Bluefin.

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

## Code of Conduct

This project follows the [Universal Blue Community Guidelines](https://docs.projectbluefin.io/contributing#community-guidelines). We are committed to providing a welcoming and inclusive environment for all contributors and users.

All participants in our community are expected to follow our code of conduct. Please report any violations to the project maintainers.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### Third-Party Components

Bluefin incorporates and builds upon several open source projects:
- **Fedora Linux** - Base operating system foundation
- **GNOME Desktop Environment** - Desktop interface
- **Universal Blue** - Cloud Native desktop infrastructure
- **Various CNCF Projects** - Cloud-native tooling and containers

All incorporated components maintain their respective licenses and attributions.

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
