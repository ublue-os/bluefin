# Bluefin 
*Deinonychus antirrhopus*

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/2503a44c1105456483517f793af75ee7)](https://app.codacy.com/gh/ublue-os/bluefin/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade) [![GTS Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-gts.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-gts.yml)[![Stable Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-stable.yml)[![Latest Images](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/bluefin/actions/workflows/build-image-latest-main.yml)

[<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/ublue-os/countme/main/badge-endpoints/bluefin.json&label=Bluefin&logo=data:image%2Fpng;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB%2BkHDxYrIEJpLs8AAAXQSURBVFjD7ZZrbFtnGcf%2F55z3XO1jJ7ZjO7c2Sd1bmnVNM5o2tIh2mgYf6IYYk5iAsolREAMJaRI3CZAmkCYkJk0UpKBpW7VVRR0S64o2NNY1nVibdkvWdk7WS2wnji%2BxHdvpOcfnfg6fQEOwSkiJ%2BJLf9%2Bd9fh%2Be93n%2BwDrrrPN%2FhlrrBjs7H4kM7OvfF44mDsf6kgfqRAyYrZW3i6cmvnNu5g86WavGI9u%2BzX%2F2C596SZDbvxQRWMo1W5idnQHXl0L3th1HFuOXZzGDp5m1EggbA0O7eq1nmfo8ZVXyWFnKI5XqQUuKwFGbkCNyKub3HFszgZqVXhrq3b0NvudUm3bS79kINdIF17DgwQXLC22Tpy7Pr4nA%2FWNPEK7Rv%2F319PO%2FjyV2jbu6Je%2FZIOyLGg1wKxVoQghEECBE2MKqDeHm2CPJ%2BHB8%2F5bR0WGfpr9JeDZOeGHJVJV3qrcyk1ud5Sc7E6GEJIhYau%2BDRhF8dOnK5B0FDg49ThZzy2ObH9j9XYbmUjRhZgPt4ZuU55amXjkHe8XwEju6tvfvH34sMbC5TZQk0FIIvmdDWa4gHIvD1nWYug61VkG4fB0hiYMR7Ydi2yjfyP3yEwUevu%2F7T3WPjf6gs6s7wPM8bB%2BAIKJFCBzTg0cBlOvArFdA0wxc1wANAoqmwXACwIvwHQueZUBr1BBKboBRyIF3W6CD7SABHlNv%2FO3R%2FxDYEnqo%2F96ffO14Isjvl2wbqqbAjSfh16qgbQuBaASaYcAmElzThG2boAkHQmhYpgUp2gGlXIQginAsEzTLgqEZUDQN13VAKAKP9qDVKrULL7%2B79d%2F2wKGxxw%2FsOvz5v0gsZLpewbKiICnRsOabkAUOK80qiFZByNCgtHfBlOMgHgOGMIAHEIaB12qBE3g0a1WwUhDNUh69Ayn4lAfLsGBRNkTiAGr16en8C%2FV%2FCXzu3qOH9o4MviaqBUlt%2BQiEg6jV6hBTG5Av5%2BHIAVxrMnAJDYuWQZVa6IYCz%2FPA8jY4QYShtSCxBIThYTsOGNdH3%2BatcD0bhqoie2sOvRt70CyXJ0pT5WcAgBlLPSrI3vaffvozqed7wgH26rUMBlOdmLyUtof7Ikwul7tQLjVemFpQzto8f5fPUBINAsBH87YGrWVgcSaDjs4OiJIEyqcAyke1WIVEXMiMDZ8PgmEoULaBWmYeMxezP5%2B4Mv4BADDtgR3S6N6O32xKyHFHbaLRbOkdvM3emC2fDHJG%2FczZpa%2B8Of3c6fncxYkOo%2Fe5Sr5%2BwYMd0xVtAPBBcSyUpoJYNAQxIAI%2BoN1uIrtQwkgY8CkCgVCwaBYsL2DuZhEs638xpG1qVfQP3yXdUfarG9rYVoyYuJatn9sS5dpW6s2reoD9xi9eftb%2F%2BIxcnHuxDuDVL3c%2BcfrU%2Bd%2F6ewYeCzoB%2Bliyt%2F2hGOdLlKHAtmzM3VyEKAdQzZfQ32uiYOgIiQJuhxK4e2QTPnjtLcCnbwAAE5UGC0M94lZVb509ebrxY8PW3i%2FowWfOnD%2Fmf9IXnZm%2FBAAoNKatUmXqzw%2BOHfxRTKR42lBx4fyHoEMByBIHDTTMhQXIroZioAODsofyrTzy2ao2XTx5BADIZOZEcTKDo%2F98%2FPoV5P%2FXLShYismprjy3qJy8XW0c4FtqiE6E5xdyyq%2B4kHP37m7%2BhzElh6wfQU1ptGyb%2Btmhe77Fnn1v3F6VWxAkqR2m7e2aTKt7BMnZa%2BrOpXJGPRrvYCjP5t%2B5q4v%2B3vKy5r3xev5EUqb%2B9NfpF3%2BdLb7vAcCq5IFszjo%2BvF04YqsrO7%2F%2B5OGhm3MLbsvwXg23i6%2BU5orpP16sDnEy2WjxZCZTcEofr10VgZ6dHRO65eu772k%2Fdv2jue7Lf79Cg2aFtra2DC8G3z6TPp4GkP5vtfRqCLx5%2FneuYVjpZIiM1GYXKFvlirpujy9kmstNw5DvVLtqkaywbJyI2I5XXNHJ6MFB8%2BrVxafemhlfRHY9eK9zZ%2F4BT9GkAVNsoqgAAAAASUVORK5CYII%3D">](https://github.com/ublue-os/bluefin)

[![LFX Active Contributors](https://insights.linuxfoundation.org/api/badge/active-contributors?project=ublue-os-bluefin&repos=https://github.com/ublue-os/bluefin)](https://insights.linuxfoundation.org/project/ublue-os-bluefin/repository/ublue-os-bluefin/security)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/bluefin-docs)

**Bluefin** is a cloud-native desktop operating system that reimagines the Linux desktop experience for modern computing environments. 

For end users, it provides a system as reliable as a Chromebook with near-zero maintenance. For developers, it offers a kickass cloud-native developer workflow with integrated container tools, declarative system management, and seamless CI/CD integration. Check [Introduction to Bluefin](https://docs.projectbluefin.io/introduction/) for a feature walkthrough.

🌐 **[Try Bluefin](https://projectbluefin.io/#scene-picker)**

![image](https://github.com/user-attachments/assets/e7d2a0af-b011-459a-8ab7-c26d3ba50ae5)

## Mission

Bluefin's mission is to provide a robust, cloud-native desktop operating system that bridges the gap between consumer usability and enterprise-grade infrastructure practices. We aim to deliver:

- **Reliability**: Atomic updates ensuring system stability
- **Developer Experience**: Integrated cloud-native tooling and workflows, including Kubernetes and container support
- **Sustainability**: Reduced maintenance overhead for contributors by using the latest cloud native infrastructure tools

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

<!-- Copy-paste in your Readme.md file -->

<a href="https://next.ossinsight.io/widgets/official/compose-org-participants-growth?activity=new&period=past_90_days&owner_id=120078124&repo_ids=611397346" target="_blank" style="display: block" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/compose-org-participants-growth/thumbnail.png?activity=new&period=past_90_days&owner_id=120078124&repo_ids=611397346&image_size=4x7&color_scheme=dark" width="657" height="auto">
    <img alt="New trends of ublue-os" src="https://next.ossinsight.io/widgets/official/compose-org-participants-growth/thumbnail.png?activity=new&period=past_90_days&owner_id=120078124&repo_ids=611397346&image_size=4x7&color_scheme=light" width="657" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->

<!-- Copy-paste in your Readme.md file -->

<a href="https://next.ossinsight.io/widgets/official/compose-org-participants-growth?activity=active&period=past_90_days&owner_id=120078124&repo_ids=611397346" target="_blank" style="display: block" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/compose-org-participants-growth/thumbnail.png?activity=active&period=past_90_days&owner_id=120078124&repo_ids=611397346&image_size=4x7&color_scheme=dark" width="657" height="auto">
    <img alt="Active trends of ublue-os" src="https://next.ossinsight.io/widgets/official/compose-org-participants-growth/thumbnail.png?activity=active&period=past_90_days&owner_id=120078124&repo_ids=611397346&image_size=4x7&color_scheme=light" width="657" height="auto">
  </picture>
</a>


## Star History

<a href="https://star-history.com/#ublue-os/bluefin&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=ublue-os/bluefin&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=ublue-os/bluefin&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=ublue-os/bluefin&type=Date" />
  </picture>
</a>
