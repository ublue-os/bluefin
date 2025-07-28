## System Requirements for Bluefin

### Quick Reference
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 64-bit x86_64 | Multi-core (4+ cores) |
| **RAM** | 16 GB | 32 GB+ |
| **Storage** | 64 GB | 128 GB SSD |
| **Graphics** | Basic display | Dedicated GPU |
| **Boot** | UEFI/BIOS | UEFI with Secure Boot |

### Why 16 GB RAM Minimum?

Bluefin ships with an extensive cloud-native development stack that requires significantly more memory than base Fedora:

**Container Runtime**: Docker CE, Podman, and container composition tools
**Development Tools**: Multiple language runtimes and development environments  
**Desktop Environment**: Modern GNOME with extensions and visual effects
**System Architecture**: Atomic/immutable OS with OSTree requiring additional overhead

*These requirements ensure smooth operation of Bluefin's integrated development workflow and container-first architecture.*

---
*Requirements based on upstream Fedora specifications with Bluefin-specific adjustments*