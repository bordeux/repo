# Bordeux Repository Installer

[![Test Install Script](https://github.com/bordeux/repo/actions/workflows/test-install.yml/badge.svg)](https://github.com/bordeux/repo/actions/workflows/test-install.yml)

Universal installer script for adding Bordeux package repositories across multiple operating systems.

## Quick Start

**Install repository only:**

```bash
curl -fsSL https://raw.githubusercontent.com/bordeux/repo/master/install.sh | sh
```

**Install repository and a package:**

```bash
curl -fsSL https://raw.githubusercontent.com/bordeux/repo/master/install.sh | sh -s -- tmpltool
```

## Supported Operating Systems

| OS | Package Manager | Detection Method |
|----|-----------------|------------------|
| macOS | Homebrew | `uname -s` = Darwin |
| Debian/Ubuntu | APT | `/etc/debian_version` or `apt` |
| Arch Linux | Pacman | `/etc/arch-release` or `pacman` |
| Alpine Linux | APK | `/etc/alpine-release` |
| Fedora/RHEL/CentOS | DNF/YUM | `/etc/redhat-release` or `dnf`/`yum` |

## Usage

```bash
./install.sh [app_name]
```

| Argument | Description |
|----------|-------------|
| (none) | Installs only the repository |
| `app_name` | Installs the repository and the specified application |

## What the Script Does

### macOS (Homebrew)

1. Verifies Homebrew is installed
2. Adds the `bordeux/tap` tap
3. Optionally installs the specified formula

### Debian/Ubuntu (APT)

1. Creates `/etc/apt/keyrings` directory
2. Downloads and installs the GPG key
3. Adds the repository to `/etc/apt/sources.list.d/bordeux.list`
4. Runs `apt update`
5. Optionally installs the specified package

### Arch Linux (Pacman)

1. Appends the `[bordeux]` repository to `/etc/pacman.conf`
2. Runs `pacman -Sy` to sync databases
3. Optionally installs the specified package

### Alpine Linux (APK)

1. Downloads the RSA public key to `/etc/apk/keys/`
2. Adds the repository URL to `/etc/apk/repositories`
3. Runs `apk update`
4. Optionally installs the specified package

### Fedora/RHEL/CentOS (DNF/YUM)

1. Downloads the `.repo` file to `/etc/yum.repos.d/`
2. Imports the GPG key
3. Optionally installs the specified package

## Repository Sources

- **Homebrew**: [bordeux/homebrew-tap](https://github.com/bordeux/homebrew-tap)
- **APT**: [bordeux/apt-repo](https://github.com/bordeux/apt-repo)
- **Pacman**: [bordeux/arch-repo](https://github.com/bordeux/arch-repo)
- **APK**: [bordeux/apk-repo](https://github.com/bordeux/apk-repo)
- **RPM**: [bordeux/rpm-repo](https://github.com/bordeux/rpm-repo)

## Manual Installation

If you prefer to set up repositories manually, see the README in each repository above.

## License

MIT