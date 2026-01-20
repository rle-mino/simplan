#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/rle-mino/simplan.git"
INSTALL_MODE="local"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            INSTALL_MODE="global"
            shift
            ;;
        --help|-h)
            echo "Usage: curl -fsSL .../install.sh | bash -s -- [OPTIONS]"
            echo ""
            echo "Install simplan commands and agents for Claude Code."
            echo ""
            echo "Options:"
            echo "  --global, -g    Install globally (XDG compliant: ~/.config/simplan-source)"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "By default, installs locally to .claude/ in the current directory."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Create temp directory and clone
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${YELLOW}Cloning simplan...${NC}"
git clone --quiet "$REPO_URL" "$TEMP_DIR/simplan"

SOURCE_DIR="$TEMP_DIR/simplan"

# Read version from cloned repo
NEW_VERSION=$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "unknown")

# Function to clean up deprecated simplan files
# Only removes files matching simplan patterns that no longer exist in source
cleanup_deprecated_files() {
    local dest_dir="$1"
    local source_dir="$2"
    local pattern="$3"
    local cleaned=0

    # Find files matching pattern in destination
    for dest_file in "$dest_dir"/$pattern; do
        [[ -e "$dest_file" ]] || continue
        filename=$(basename "$dest_file")

        # Check if this file exists in source
        if [[ ! -f "$source_dir/$filename" ]]; then
            # For symlinks, remove. For regular files, also remove.
            rm -f "$dest_file"
            echo -e "  ${YELLOW}Removed deprecated: $filename${NC}"
            ((cleaned++))
        fi
    done

    return $cleaned
}

if [[ "$INSTALL_MODE" == "global" ]]; then
    # XDG Base Directory compliant paths
    SIMPLAN_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/simplan-source"
    TARGET_DIR="$HOME/.claude"
    VERSION_FILE="$SIMPLAN_CONFIG_DIR/.version"

    # Check for existing installation
    if [[ -f "$VERSION_FILE" ]]; then
        OLD_VERSION=$(cat "$VERSION_FILE")
        if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
            echo -e "${CYAN}Reinstalling simplan v${NEW_VERSION} globally${NC}"
        else
            echo -e "${CYAN}Updating simplan: v${OLD_VERSION} → v${NEW_VERSION}${NC}"
        fi
    else
        echo -e "${YELLOW}Installing simplan v${NEW_VERSION} globally${NC}"
    fi

    # Copy source to permanent location for symlinks
    rm -rf "$SIMPLAN_CONFIG_DIR"
    mkdir -p "$SIMPLAN_CONFIG_DIR"
    cp -r "$SOURCE_DIR"/* "$SIMPLAN_CONFIG_DIR/"

    # Write version file
    echo "$NEW_VERSION" > "$VERSION_FILE"

    # Create directories
    mkdir -p "$TARGET_DIR/commands" "$TARGET_DIR/agents"

    # Clean up deprecated simplan files before adding new ones
    echo -e "${CYAN}Checking for deprecated files...${NC}"
    cleanup_deprecated_files "$TARGET_DIR/commands" "$SIMPLAN_CONFIG_DIR/commands" "item:*.md"
    cleanup_deprecated_files "$TARGET_DIR/agents" "$SIMPLAN_CONFIG_DIR/agents" "simplan:*.md"

    # Symlink commands
    for file in "$SIMPLAN_CONFIG_DIR/commands"/*.md; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/commands/$filename"
    done

    # Symlink agents
    for file in "$SIMPLAN_CONFIG_DIR/agents"/*.md; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/agents/$filename"
    done

    echo -e "${GREEN}✓ Installed source to $SIMPLAN_CONFIG_DIR${NC}"
    echo -e "${GREEN}✓ Symlinked commands to ~/.claude/commands/${NC}"
    echo -e "${GREEN}✓ Symlinked agents to ~/.claude/agents/${NC}"
    echo ""
    echo "Simplan v${NEW_VERSION} is now available in all projects."

else
    TARGET_DIR=".claude"
    VERSION_FILE="$TARGET_DIR/.simplan-version"

    # Check for existing installation
    if [[ -f "$VERSION_FILE" ]]; then
        OLD_VERSION=$(cat "$VERSION_FILE")
        if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
            echo -e "${CYAN}Reinstalling simplan v${NEW_VERSION} locally${NC}"
        else
            echo -e "${CYAN}Updating simplan: v${OLD_VERSION} → v${NEW_VERSION}${NC}"
        fi
    else
        echo -e "${YELLOW}Installing simplan v${NEW_VERSION} locally to .claude/${NC}"
    fi

    # Create directories
    mkdir -p "$TARGET_DIR/commands" "$TARGET_DIR/agents"

    # Clean up deprecated simplan files before adding new ones
    echo -e "${CYAN}Checking for deprecated files...${NC}"
    cleanup_deprecated_files "$TARGET_DIR/commands" "$SOURCE_DIR/commands" "item:*.md"
    cleanup_deprecated_files "$TARGET_DIR/agents" "$SOURCE_DIR/agents" "simplan:*.md"

    # Copy commands
    for file in "$SOURCE_DIR/commands"/*.md; do
        [[ -e "$file" ]] || continue
        cp "$file" "$TARGET_DIR/commands/"
    done

    # Copy agents
    for file in "$SOURCE_DIR/agents"/*.md; do
        [[ -e "$file" ]] || continue
        cp "$file" "$TARGET_DIR/agents/"
    done

    # Write version file
    echo "$NEW_VERSION" > "$VERSION_FILE"

    echo -e "${GREEN}✓ Copied commands to .claude/commands/${NC}"
    echo -e "${GREEN}✓ Copied agents to .claude/agents/${NC}"
    echo ""
    echo "Simplan v${NEW_VERSION} is now available in this project."
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Initialize simplan in your project:"
echo "  mkdir -p .simplan/plans && touch .simplan/ITEMS.md"
echo ""
echo "Get started:"
echo "  /item:add           - Add a new work item"
echo "  /item:plan 1        - Plan item #1"
echo "  # OR"
echo "  /item:brainstorm 1  - Brainstorm to plan item #1"
echo "  /item:exec          - Execute the next phase of the current item"
echo "  /item:help          - Show full documentation"
