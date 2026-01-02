#!/bin/sh
set -e

# Bordeux Repository Installer
# Usage: ./install.sh [app_name]
# Without app_name: installs only the repository
# With app_name: installs the repository and the specified app

# Configuration
REPO_NAME="bordeux"
REPO_OWNER="bordeux"
GITHUB_PAGES_BASE="https://${REPO_OWNER}.github.io"

# Repository URLs
HOMEBREW_TAP="${REPO_OWNER}/tap"
APT_REPO_URL="${GITHUB_PAGES_BASE}/apt-repo"
ARCH_REPO_URL="${GITHUB_PAGES_BASE}/arch-repo"
APK_REPO_URL="${GITHUB_PAGES_BASE}/apk-repo"
RPM_REPO_URL="${GITHUB_PAGES_BASE}/rpm-repo"

APP_NAME="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Use sudo only if not running as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

print_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[OK]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

detect_os() {
    os_type=""

    # Check for macOS
    if [ "$(uname -s)" = "Darwin" ]; then
        os_type="macos"
    # Check for Linux distributions
    elif [ "$(uname -s)" = "Linux" ]; then
        # Alpine Linux
        if [ -f /etc/alpine-release ]; then
            os_type="alpine"
        # Arch Linux
        elif [ -f /etc/arch-release ] || command -v pacman >/dev/null 2>&1; then
            os_type="arch"
        # Debian-based (Debian, Ubuntu, etc.)
        elif [ -f /etc/debian_version ] || command -v apt >/dev/null 2>&1; then
            os_type="debian"
        # RedHat-based (Fedora, RHEL, CentOS, Rocky, etc.)
        elif [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ] || command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
            os_type="redhat"
        fi
    fi

    echo "$os_type"
}

install_macos() {
    print_info "Detected macOS - using Homebrew"

    # Check if Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        print_error "Homebrew is not installed. Please install it first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    # Add tap
    print_info "Adding ${HOMEBREW_TAP}..."
    brew tap "${HOMEBREW_TAP}"
    print_success "Repository added successfully"

    # Install app if specified
    if [ -n "$APP_NAME" ]; then
        print_info "Installing $APP_NAME..."
        brew install "${HOMEBREW_TAP}/$APP_NAME"
        print_success "$APP_NAME installed successfully"
    fi
}

install_debian() {
    print_info "Detected Debian-based Linux - using APT"

    # Check for required commands
    if ! command -v apt >/dev/null 2>&1; then
        print_error "apt is not available on this system"
        exit 1
    fi

    # Create keyrings directory if it doesn't exist
    print_info "Setting up GPG key..."
    $SUDO mkdir -p /etc/apt/keyrings

    # Download and install the GPG key
    curl -fsSL "${APT_REPO_URL}/public.key" | $SUDO gpg --dearmor -o "/etc/apt/keyrings/${REPO_NAME}.gpg"

    # Add the repository
    print_info "Adding repository..."
    echo "deb [signed-by=/etc/apt/keyrings/${REPO_NAME}.gpg] ${APT_REPO_URL} stable main" | $SUDO tee "/etc/apt/sources.list.d/${REPO_NAME}.list" > /dev/null

    # Update package lists
    print_info "Updating package lists..."
    $SUDO apt update
    print_success "Repository added successfully"

    # Install app if specified
    if [ -n "$APP_NAME" ]; then
        print_info "Installing $APP_NAME..."
        $SUDO apt install -y "$APP_NAME"
        print_success "$APP_NAME installed successfully"
    fi
}

install_arch() {
    print_info "Detected Arch-based Linux - using Pacman"

    # Check for required commands
    if ! command -v pacman >/dev/null 2>&1; then
        print_error "pacman is not available on this system"
        exit 1
    fi

    # Import GPG key
    print_info "Importing GPG key..."
    $SUDO pacman-key --init 2>/dev/null || true
    curl -fsSL "${ARCH_REPO_URL}/keys/${REPO_NAME}.gpg" -o /tmp/${REPO_NAME}.gpg 2>/dev/null && \
        $SUDO pacman-key --add /tmp/${REPO_NAME}.gpg 2>/dev/null && \
        rm -f /tmp/${REPO_NAME}.gpg || print_warning "GPG key import skipped (may not be signed)"

    pacman_conf="/etc/pacman.conf"

    # Check if repository is already added
    if grep -q "^\[${REPO_NAME}\]" "$pacman_conf" 2>/dev/null; then
        print_warning "Repository already exists in $pacman_conf"
    else
        print_info "Adding repository to $pacman_conf..."
        $SUDO tee -a "$pacman_conf" > /dev/null <<EOF

[${REPO_NAME}]
SigLevel = Optional TrustAll
Server = ${ARCH_REPO_URL}/\$arch
EOF
        print_success "Repository added successfully"
    fi

    # Sync package databases
    print_info "Syncing package databases..."
    $SUDO pacman -Sy

    # Install app if specified
    if [ -n "$APP_NAME" ]; then
        print_info "Installing $APP_NAME..."
        $SUDO pacman -S --noconfirm "$APP_NAME"
        print_success "$APP_NAME installed successfully"
    fi
}

install_alpine() {
    print_info "Detected Alpine Linux - using APK"

    # Check for required commands
    if ! command -v apk >/dev/null 2>&1; then
        print_error "apk is not available on this system"
        exit 1
    fi

    # Download and install the public key
    print_info "Setting up RSA key..."
    $SUDO mkdir -p /etc/apk/keys
    $SUDO curl -fsSL -o "/etc/apk/keys/alpine@${REPO_NAME}.rsa.pub" "${APK_REPO_URL}/keys/alpine@${REPO_NAME}.rsa.pub"

    # Add repository if not already present
    if grep -q "${APK_REPO_URL}" /etc/apk/repositories 2>/dev/null; then
        print_warning "Repository already exists in /etc/apk/repositories"
    else
        print_info "Adding repository..."
        echo "${APK_REPO_URL}" | $SUDO tee -a /etc/apk/repositories > /dev/null
        print_success "Repository added successfully"
    fi

    # Update package index
    print_info "Updating package index..."
    $SUDO apk update

    # Install app if specified
    if [ -n "$APP_NAME" ]; then
        print_info "Installing $APP_NAME..."
        $SUDO apk add "$APP_NAME"
        print_success "$APP_NAME installed successfully"
    fi
}

install_redhat() {
    print_info "Detected RedHat-based Linux - using DNF/YUM"

    # Determine package manager (prefer dnf over yum)
    pkg_manager=""
    if command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
        pkg_manager="yum"
    else
        print_error "Neither dnf nor yum is available on this system"
        exit 1
    fi

    # Download the .repo file
    print_info "Adding repository..."
    $SUDO curl -fsSL -o "/etc/yum.repos.d/${REPO_NAME}.repo" "${RPM_REPO_URL}/${REPO_NAME}.repo"

    # Import GPG key
    print_info "Importing GPG key..."
    $SUDO rpm --import "${RPM_REPO_URL}/RPM-GPG-KEY-${REPO_NAME}" 2>/dev/null || print_warning "GPG key import skipped (may not be signed)"

    print_success "Repository added successfully"

    # Install app if specified
    if [ -n "$APP_NAME" ]; then
        print_info "Installing $APP_NAME..."
        $SUDO $pkg_manager install -y "$APP_NAME"
        print_success "$APP_NAME installed successfully"
    fi
}

main() {
    echo "=========================================="
    echo "   ${REPO_NAME} Repository Installer"
    echo "=========================================="
    echo

    # Detect OS type
    os_type=$(detect_os)

    if [ -z "$os_type" ]; then
        print_error "Could not detect OS type. Supported systems:"
        echo "  - macOS (Homebrew)"
        echo "  - Debian/Ubuntu (APT)"
        echo "  - Arch Linux (Pacman)"
        echo "  - Alpine Linux (APK)"
        echo "  - Fedora/RHEL/CentOS (DNF/YUM)"
        exit 1
    fi

    # Install based on OS type
    case "$os_type" in
        macos)
            install_macos
            ;;
        debian)
            install_debian
            ;;
        arch)
            install_arch
            ;;
        alpine)
            install_alpine
            ;;
        redhat)
            install_redhat
            ;;
        *)
            print_error "Unsupported OS type: $os_type"
            exit 1
            ;;
    esac

    echo
    print_success "Done!"
    if [ -z "$APP_NAME" ]; then
        print_info "Repository installed. You can now install packages from the ${REPO_NAME} repository."
    fi
}

main "$@"
