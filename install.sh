#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/rle-mino/simplan.git"
INSTALL_MODE="local"
PLATFORM=""  # Will be auto-detected or specified
DEV_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            INSTALL_MODE="global"
            shift
            ;;
        --claude)
            PLATFORM="claude"
            shift
            ;;
        --opencode)
            PLATFORM="opencode"
            shift
            ;;
        --dev|-d)
            DEV_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: curl -fsSL .../install.sh | bash -s -- [OPTIONS]"
            echo ""
            echo "Install simplan commands and agents for Claude Code or OpenCode."
            echo ""
            echo "Options:"
            echo "  --global, -g    Install globally (XDG compliant: ~/.config/simplan-source)"
            echo "  --claude        Install for Claude Code (default if .claude/ exists)"
            echo "  --opencode      Install for OpenCode (default if .opencode/ exists)"
            echo "  --dev, -d       Use local source directory instead of cloning from GitHub"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Platform is auto-detected if not specified:"
            echo "  - If .claude/ exists → Claude Code"
            echo "  - If .opencode/ exists → OpenCode"
            echo "  - Otherwise prompts for selection"
            echo ""
            echo "By default, installs locally to .claude/ or .opencode/ in the current directory."
            echo ""
            echo "Development mode (--dev):"
            echo "  Use this when testing local changes before publishing."
            echo "  Run from the simplan repository directory."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Function to detect platform
detect_platform() {
    if [[ -n "$PLATFORM" ]]; then
        return
    fi
    
    local has_claude=false
    local has_opencode=false
    
    # Check for existing installations
    if [[ "$INSTALL_MODE" == "global" ]]; then
        [[ -d "$HOME/.claude" ]] && has_claude=true
        [[ -d "$HOME/.config/opencode" ]] && has_opencode=true
    else
        [[ -d ".claude" ]] && has_claude=true
        [[ -d ".opencode" ]] && has_opencode=true
    fi
    
    if [[ "$has_claude" == true && "$has_opencode" == false ]]; then
        PLATFORM="claude"
        echo -e "${CYAN}Detected Claude Code installation${NC}"
    elif [[ "$has_opencode" == true && "$has_claude" == false ]]; then
        PLATFORM="opencode"
        echo -e "${CYAN}Detected OpenCode installation${NC}"
    elif [[ "$has_claude" == true && "$has_opencode" == true ]]; then
        echo -e "${YELLOW}Both Claude Code and OpenCode detected.${NC}"
        echo "Please specify: --claude or --opencode"
        exit 1
    else
        # No existing installation - prompt user
        echo -e "${YELLOW}No existing installation detected.${NC}"
        echo ""
        echo "Which platform do you want to install for?"
        echo "  1) Claude Code"
        echo "  2) OpenCode"
        echo ""
        read -p "Enter choice [1-2]: " choice
        case $choice in
            1) PLATFORM="claude" ;;
            2) PLATFORM="opencode" ;;
            *)
                echo -e "${RED}Invalid choice. Please run again with --claude or --opencode${NC}"
                exit 1
                ;;
        esac
    fi
}

# Determine source directory
if [[ "$DEV_MODE" == true ]]; then
    # Dev mode: use local directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SOURCE_DIR="$SCRIPT_DIR"
    
    # Verify we're in a simplan repo
    if [[ ! -f "$SOURCE_DIR/VERSION" ]] || [[ ! -d "$SOURCE_DIR/src" ]]; then
        echo -e "${RED}Error: --dev must be run from the simplan repository directory${NC}"
        echo "Expected to find VERSION file and src/ directory"
        exit 1
    fi
    
    echo -e "${YELLOW}Using local source directory (dev mode)${NC}"
    NEW_VERSION=$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "dev")
else
    # Normal mode: clone from GitHub
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo -e "${YELLOW}Cloning simplan...${NC}"
    git clone --quiet "$REPO_URL" "$TEMP_DIR/simplan"

    SOURCE_DIR="$TEMP_DIR/simplan"
    NEW_VERSION=$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "unknown")
fi

# Run the build to generate platform-specific files (if src/ exists)
if [[ -d "$SOURCE_DIR/src" ]]; then
    echo -e "${YELLOW}Building platform-specific files...${NC}"
    cd "$SOURCE_DIR"
    if ! bash ./build.sh; then
        echo -e "${RED}Build failed${NC}"
        exit 1
    fi
    cd - > /dev/null
else
    # Legacy mode: src/ doesn't exist, use old structure with commands/ and agents/
    # This handles repos that haven't been updated yet
    echo -e "${YELLOW}Using legacy structure (no src/ directory)${NC}"
    mkdir -p "$SOURCE_DIR/dist/claude/commands" "$SOURCE_DIR/dist/claude/agents"
    mkdir -p "$SOURCE_DIR/dist/opencode/commands" "$SOURCE_DIR/dist/opencode/agents"
    
    # Copy commands (Claude uses colons, OpenCode uses hyphens)
    for file in "$SOURCE_DIR/commands"/*.md; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        cp "$file" "$SOURCE_DIR/dist/claude/commands/$filename"
        # For OpenCode, replace colons with hyphens in filename
        opencode_filename=$(echo "$filename" | sed 's/:/-/g')
        cp "$file" "$SOURCE_DIR/dist/opencode/commands/$opencode_filename"
    done
    
    # Copy agents
    for file in "$SOURCE_DIR/agents"/*.md; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        cp "$file" "$SOURCE_DIR/dist/claude/agents/$filename"
        opencode_filename=$(echo "$filename" | sed 's/:/-/g')
        cp "$file" "$SOURCE_DIR/dist/opencode/agents/$opencode_filename"
    done
fi

# Detect platform
detect_platform

echo -e "${CYAN}Installing for: ${PLATFORM}${NC}"

# Set platform-specific variables
if [[ "$PLATFORM" == "claude" ]]; then
    PLATFORM_DIR=".claude"
    COMMAND_PATTERN="item:*.md"
    AGENT_PATTERN="simplan:*.md"
    DIST_SUBDIR="claude"
else
    PLATFORM_DIR=".opencode"
    COMMAND_PATTERN="item-*.md"
    AGENT_PATTERN="simplan-*.md"
    DIST_SUBDIR="opencode"
fi

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
    
    if [[ "$PLATFORM" == "claude" ]]; then
        TARGET_DIR="$HOME/.claude"
    else
        TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
    fi
    
    VERSION_FILE="$SIMPLAN_CONFIG_DIR/.version"

    # Check for existing installation
    if [[ -f "$VERSION_FILE" ]]; then
        OLD_VERSION=$(cat "$VERSION_FILE")
        if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
            echo -e "${CYAN}Reinstalling simplan v${NEW_VERSION} globally for ${PLATFORM}${NC}"
        else
            echo -e "${CYAN}Updating simplan: v${OLD_VERSION} → v${NEW_VERSION}${NC}"
        fi
    else
        echo -e "${YELLOW}Installing simplan v${NEW_VERSION} globally for ${PLATFORM}${NC}"
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
    cleanup_deprecated_files "$TARGET_DIR/commands" "$SIMPLAN_CONFIG_DIR/dist/$DIST_SUBDIR/commands" "$COMMAND_PATTERN"
    cleanup_deprecated_files "$TARGET_DIR/agents" "$SIMPLAN_CONFIG_DIR/dist/$DIST_SUBDIR/agents" "$AGENT_PATTERN"

    # Symlink commands
    for file in "$SIMPLAN_CONFIG_DIR/dist/$DIST_SUBDIR/commands"/*.md; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/commands/$filename"
    done

    # Symlink agents
    for file in "$SIMPLAN_CONFIG_DIR/dist/$DIST_SUBDIR/agents"/*.md; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        ln -sf "$file" "$TARGET_DIR/agents/$filename"
    done

    echo -e "${GREEN}✓ Installed source to $SIMPLAN_CONFIG_DIR${NC}"
    echo -e "${GREEN}✓ Symlinked commands to $TARGET_DIR/commands/${NC}"
    echo -e "${GREEN}✓ Symlinked agents to $TARGET_DIR/agents/${NC}"
    echo ""
    echo "Simplan v${NEW_VERSION} is now available in all projects."
    echo ""
    echo -e "${CYAN}Note: Add .simplan/ to each project's .gitignore to avoid${NC}"
    echo -e "${CYAN}committing plan files. Run this in your project directory:${NC}"
    echo -e "${CYAN}  echo '.simplan/' >> .gitignore${NC}"

else
    TARGET_DIR="$PLATFORM_DIR"
    VERSION_FILE="$TARGET_DIR/.simplan-version"

    # Check for existing installation
    if [[ -f "$VERSION_FILE" ]]; then
        OLD_VERSION=$(cat "$VERSION_FILE")
        if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
            echo -e "${CYAN}Reinstalling simplan v${NEW_VERSION} locally for ${PLATFORM}${NC}"
        else
            echo -e "${CYAN}Updating simplan: v${OLD_VERSION} → v${NEW_VERSION}${NC}"
        fi
    else
        echo -e "${YELLOW}Installing simplan v${NEW_VERSION} locally to $TARGET_DIR/${NC}"
    fi

    # Create directories
    mkdir -p "$TARGET_DIR/commands" "$TARGET_DIR/agents"

    # Clean up deprecated simplan files before adding new ones
    echo -e "${CYAN}Checking for deprecated files...${NC}"
    cleanup_deprecated_files "$TARGET_DIR/commands" "$SOURCE_DIR/dist/$DIST_SUBDIR/commands" "$COMMAND_PATTERN"
    cleanup_deprecated_files "$TARGET_DIR/agents" "$SOURCE_DIR/dist/$DIST_SUBDIR/agents" "$AGENT_PATTERN"

    # Copy commands
    for file in "$SOURCE_DIR/dist/$DIST_SUBDIR/commands"/*.md; do
        [[ -e "$file" ]] || continue
        cp "$file" "$TARGET_DIR/commands/"
    done

    # Copy agents
    for file in "$SOURCE_DIR/dist/$DIST_SUBDIR/agents"/*.md; do
        [[ -e "$file" ]] || continue
        cp "$file" "$TARGET_DIR/agents/"
    done

    # Write version file
    echo "$NEW_VERSION" > "$VERSION_FILE"

    echo -e "${GREEN}✓ Copied commands to $TARGET_DIR/commands/${NC}"
    echo -e "${GREEN}✓ Copied agents to $TARGET_DIR/agents/${NC}"
    echo ""
    echo "Simplan v${NEW_VERSION} is now available in this project."
fi

# Add .simplan/ to .gitignore (local install only - global install handles this at runtime)
if [[ "$INSTALL_MODE" == "local" ]]; then
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "^\.simplan/?$\|^\.simplan$" ".gitignore" 2>/dev/null; then
            echo ".simplan/" >> ".gitignore"
            echo -e "${GREEN}✓ Added .simplan/ to .gitignore${NC}"
        fi
    elif [[ -d ".git" ]]; then
        # Git repo exists but no .gitignore - create one
        echo ".simplan/" > ".gitignore"
        echo -e "${GREEN}✓ Created .gitignore with .simplan/${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Initialize simplan in your project:"
echo "  mkdir -p .simplan/plans && touch .simplan/ITEMS.md"
echo ""

# Show platform-specific command examples
if [[ "$PLATFORM" == "claude" ]]; then
    echo "Get started:"
    echo "  /item:add           - Add a new work item"
    echo "  /item:plan 1        - Plan item #1"
    echo "  # OR"
    echo "  /item:brainstorm 1  - Brainstorm to plan item #1"
    echo "  /item:exec          - Execute the next phase of the current item"
    echo "  /item:help          - Show full documentation"
else
    echo "Get started:"
    echo "  /item-add           - Add a new work item"
    echo "  /item-plan 1        - Plan item #1"
    echo "  # OR"
    echo "  /item-brainstorm 1  - Brainstorm to plan item #1"
    echo "  /item-exec          - Execute the next phase of the current item"
    echo "  /item-help          - Show full documentation"
fi
