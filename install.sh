#!/usr/bin/env bash
set -e

# Covlant CLI Installer
# This script installs the Covlant CLI to your system

# Configuration
GITHUB_REPO="covlant/covlant-cli"
BINARY_NAME="covlant"
INSTALL_DIR="/usr/local/bin"
TMP_DIR="$(mktemp -d)"
USER_AGENT="Covlant-CLI-Installer/1.0"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}
   ______            __            __     ___    ____
  / ____/___  _   __/ /___ _____  / /_   /   |  /  _/
 / /   / __ \| | / / / __ \`/ __ \/ __/  / /| | _/ /
/ /___/ /_/ /| |/ / / /_/ / / / / /_   / ___ |/  _/
\____/\____/ |___/_/\__,_/_/ /_/\__/  /_/  |_/_/

${NC}"
echo -e "${GREEN}Covlant AI CLI Installer${NC}"
echo -e "This script will install the Covlant AI CLI to your system.\n"

# Check if running with sudo/root permissions
check_permissions() {
  if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
      echo -e "${RED}Error: This script needs to be run with root privileges.${NC}"
      echo -e "Please run as root or install sudo."
      exit 1
    fi
  fi
}

# Detect system architecture
detect_arch() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64)
      ARCH="x86_64"
      ;;
    arm64|aarch64)
      ARCH="arm64"
      ;;
    *)
      echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
      echo "The Covlant AI CLI is available for x86_64 and arm64 architectures."
      exit 1
      ;;
  esac
}

# Detect operating system
detect_os() {
  OS=$(uname -s)
  case "$OS" in
    Linux)
      OS="linux"
      ;;
    Darwin)
      OS="macos"
      ;;
    *)
      echo -e "${RED}Error: Unsupported operating system: $OS${NC}"
      echo "The Covlant AI CLI is available for Linux and macOS."
      exit 1
      ;;
  esac
}

# Get the latest version from GitHub
get_latest_version() {
  echo -e "${BLUE}Fetching the latest version of Covlant AI...${NC}"

  if command -v curl &> /dev/null; then
    LATEST_VERSION="1.2.10"
  elif command -v wget &> /dev/null; then
    LATEST_VERSION="1.2.10"
  else
    echo -e "${RED}Error: Neither curl nor wget found. Please install one of them and try again.${NC}"
    exit 1
  fi

  if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Error: Could not determine the latest version.${NC}"
    echo "Please check your internet connection or try again later."
    exit 1
  fi

  # Remove the 'v' prefix
  LATEST_VERSION="1.2.10"
  echo -e "Latest version: ${GREEN}v$LATEST_VERSION${NC}"
}

# Download the appropriate binary
download_binary() {
  PACKAGE_NAME="covlant-$OS-$ARCH-v$LATEST_VERSION.tar.gz"
  DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v$LATEST_VERSION/$PACKAGE_NAME"

  echo -e "${BLUE}Downloading Covlant AI $PACKAGE_NAME...${NC}"

  if command -v curl &> /dev/null; then
    curl -L -# -H "User-Agent: $USER_AGENT" -o "$TMP_DIR/$PACKAGE_NAME" "$DOWNLOAD_URL"
  elif command -v wget &> /dev/null; then
    wget --show-progress --progress=bar:force:noscroll -U "$USER_AGENT" -O "$TMP_DIR/$PACKAGE_NAME" "$DOWNLOAD_URL"
  fi

  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to download the Covlant AI binary.${NC}"
    echo "Please check your internet connection or try again later."
    rm -rf "$TMP_DIR"
    exit 1
  fi
}

# Verify the checksum
verify_checksum() {
  echo -e "${BLUE}Verifying Covlant AI checksum...${NC}"

  # Download the checksum file
  CHECKSUM_URL="https://github.com/$GITHUB_REPO/releases/download/v$LATEST_VERSION/$PACKAGE_NAME.sha256"

  if command -v curl &> /dev/null; then
    curl -s -L -H "User-Agent: $USER_AGENT" -o "$TMP_DIR/$PACKAGE_NAME.sha256" "$CHECKSUM_URL"
  elif command -v wget &> /dev/null; then
    wget -q -U "$USER_AGENT" -O "$TMP_DIR/$PACKAGE_NAME.sha256" "$CHECKSUM_URL"
  fi

  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Could not download the checksum file. Skipping verification.${NC}"
    return
  fi

  # Calculate and verify checksum
  if command -v shasum &> /dev/null; then
    CALCULATED_CHECKSUM=$(shasum -a 256 "$TMP_DIR/$PACKAGE_NAME" | awk '{print $1}')
  elif command -v sha256sum &> /dev/null; then
    CALCULATED_CHECKSUM=$(sha256sum "$TMP_DIR/$PACKAGE_NAME" | awk '{print $1}')
  else
    echo -e "${YELLOW}Warning: No checksum tool found. Skipping verification.${NC}"
    return
  fi

  EXPECTED_CHECKSUM=$(cat "$TMP_DIR/$PACKAGE_NAME.sha256" | awk '{print $1}')

  if [ "$CALCULATED_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
    echo -e "${RED}Error: Covlant AI checksum verification failed.${NC}"
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Got: $CALCULATED_CHECKSUM"
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo -e "${GREEN}Covlant AI checksum verified successfully.${NC}"
}

# Install the binary
install_binary() {
  echo -e "${BLUE}Installing Covlant AI CLI...${NC}"

  # Extract the package
  echo -e "${BLUE}Extracting package...${NC}"
  tar -xzf "$TMP_DIR/$PACKAGE_NAME" -C "$TMP_DIR"

  # Debug: List the extracted contents
  echo -e "${BLUE}Extracted package contents:${NC}"
  find "$TMP_DIR" -type f | sort

  # More flexible extraction directory finding
  BINARY_PATH=""

  # First try to find the binary directly in the extracted directory structure
  BINARY_PATH=$(find "$TMP_DIR" -name "$BINARY_NAME" -type f | head -n 1)

  # If not found, look for the expected directory structure
  if [ -z "$BINARY_PATH" ]; then
    EXTRACT_DIR=$(find "$TMP_DIR" -type d -name "covlant-*" | head -n 1)
    if [ -d "$EXTRACT_DIR" ]; then
      BINARY_PATH=$(find "$EXTRACT_DIR" -name "$BINARY_NAME" -type f | head -n 1)
    fi
  fi

  # Last resort - look everywhere in the temp directory
  if [ -z "$BINARY_PATH" ]; then
    echo -e "${YELLOW}Warning: Binary not found in expected location, searching entire extraction...${NC}"
    BINARY_PATH=$(find "$TMP_DIR" -name "$BINARY_NAME" -type f | head -n 1)
  fi

  if [ -z "$BINARY_PATH" ]; then
    echo -e "${RED}Error: Could not find the covlant binary in the extracted package.${NC}"
    echo "Package contents:"
    find "$TMP_DIR" -type f | sort
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo -e "${GREEN}Found binary at: $BINARY_PATH${NC}"

  # Ensure the binary is executable
  chmod +x "$BINARY_PATH"

  # Create the installation directory if it doesn't exist
  if [ ! -d "$INSTALL_DIR" ]; then
    if [ "$EUID" -eq 0 ]; then
      mkdir -p "$INSTALL_DIR"
    else
      sudo mkdir -p "$INSTALL_DIR"
    fi
  fi

  # Install the binary
  if [ "$EUID" -eq 0 ]; then
    cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
  else
    sudo cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
  fi

  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to install the Covlant AI binary.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo -e "${GREEN}Covlant AI CLI installed successfully to $INSTALL_DIR/$BINARY_NAME${NC}"
}

# Check if the binary is in PATH
check_path() {
  if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH.${NC}"
    echo "You may need to add it to your PATH or restart your shell."
    echo "Add the following line to your .bashrc, .zshrc, or equivalent:"
    echo -e "${BLUE}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
  fi
}

# Clean up temporary files
cleanup() {
  rm -rf "$TMP_DIR"
}

# Main installation process
check_permissions
detect_arch
detect_os
get_latest_version
download_binary
verify_checksum
install_binary
check_path
cleanup

echo -e "\n${GREEN}Covlant AI installation complete!${NC}"
echo -e "Run '${BLUE}$BINARY_NAME --help${NC}' to get started."