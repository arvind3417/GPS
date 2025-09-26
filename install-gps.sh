#!/bin/bash

# Git Profile Switcher Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="gps.sh"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# Installation directories (in order of preference)
INSTALL_DIRS=(
    "/usr/local/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
)

echo -e "${CYAN}Git Profile Switcher Installation${NC}"
echo "=================================="
echo ""

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: $SCRIPT_NAME not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Find suitable installation directory
INSTALL_DIR=""
for dir in "${INSTALL_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        INSTALL_DIR="$dir"
        break
    elif [ ! -d "$dir" ] && mkdir -p "$dir" 2>/dev/null; then
        INSTALL_DIR="$dir"
        break
    fi
done

if [ -z "$INSTALL_DIR" ]; then
    echo -e "${RED}Error: Could not find a suitable installation directory${NC}"
    echo "Please ensure one of these directories exists and is writable:"
    for dir in "${INSTALL_DIRS[@]}"; do
        echo "  - $dir"
    done
    exit 1
fi

echo -e "${YELLOW}Installing to: $INSTALL_DIR${NC}"

# Install the script
TARGET_PATH="$INSTALL_DIR/gps"
cp "$SCRIPT_PATH" "$TARGET_PATH"
chmod +x "$TARGET_PATH"

echo -e "${GREEN}✓ Installed gps to $TARGET_PATH${NC}"

# Check if installation directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH${NC}"
    echo "Add the following line to your shell configuration file:"
    echo ""
    echo -e "${BLUE}export PATH=\"$INSTALL_DIR:\$PATH\"${NC}"
    echo ""
    echo "Common shell config files:"
    echo "  - ~/.bashrc (for Bash)"
    echo "  - ~/.zshrc (for Zsh)"
    echo "  - ~/.profile (for most shells)"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "You can now use the git profile switcher with:"
echo -e "${CYAN}  gps list${NC}         # List all profiles"
echo -e "${CYAN}  gps current${NC}      # Show current profile"
echo -e "${CYAN}  gps setup${NC}        # Auto-setup from existing configs"
echo -e "${CYAN}  gps switch work${NC}  # Switch to work profile"
echo ""
echo "For more options, run: ${CYAN}gps help${NC}"

