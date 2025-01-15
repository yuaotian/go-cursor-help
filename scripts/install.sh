#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Print colored message
print_msg() {
    echo -e "${1}${2}${NC}"
}

# Handle errors and cleanup
cleanup() {
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}

trap cleanup EXIT

die() {
    print_msg "$RED" "Error: $1"
    exit 1
}

# Setup
TMP_DIR=$(mktemp -d)
INSTALL_DIR="/usr/local/bin"
command -v curl >/dev/null 2>&1 || die "curl is required"
mkdir -p "$INSTALL_DIR" || die "Failed to create installation directory"

# Detect system and binary
case "$(uname -s)" in
    Linux)  
        BINARY_PREFIX="cursor-id-modifier_Linux_x86_64"
        ;;
    Darwin)
        BINARY_PREFIX="cursor-id-modifier_macOS_universal"
        ;;
    *) 
        die "Unsupported OS"
        ;;
esac

print_msg "$BLUE" "Starting installation..."

# Download and install latest release
LATEST_URL="https://api.github.com/repos/yuaotian/go-cursor-help/releases/latest"
VERSION=$(curl -s "$LATEST_URL" | grep "tag_name" | cut -d'"' -f4)
DOWNLOAD_URL=$(curl -s "$LATEST_URL" | grep -o "\"browser_download_url\": \"[^\"]*${BINARY_PREFIX}[^\"]*\"" | cut -d'"' -f4)

[ -z "$DOWNLOAD_URL" ] && die "Binary not found"

print_msg "$BLUE" "Downloading version $VERSION..."

curl -#L "$DOWNLOAD_URL" -o "$TMP_DIR/cursor-id-modifier" || die "Download failed"
chmod +x "$TMP_DIR/cursor-id-modifier"
sudo mv "$TMP_DIR/cursor-id-modifier" "$INSTALL_DIR/"

print_msg "$GREEN" "Installation complete!"
print_msg "$BLUE" "Running cursor-id-modifier..."

# Run with automated mode
export AUTOMATED_MODE=1
sudo -E cursor-id-modifier || die "Failed to run cursor-id-modifier"
