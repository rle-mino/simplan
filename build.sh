#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
DIST_DIR="$SCRIPT_DIR/dist"

echo -e "${CYAN}Building simplan for Claude Code and OpenCode...${NC}"

# Clean dist directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/claude/commands" "$DIST_DIR/claude/agents"
mkdir -p "$DIST_DIR/opencode/commands" "$DIST_DIR/opencode/agents"

# Function to convert universal tools list to Claude format
convert_tools_claude() {
    local tools="$1"
    # Tools are already in the right format for Claude (YAML list)
    echo "$tools"
}

# Function to convert universal tools list to OpenCode format
convert_tools_opencode() {
    local tools="$1"
    # Convert YAML list to OpenCode tools object
    # Input: "Read, Write, Edit" or multiline "- Read\n- Write"
    # Output: YAML object format
    
    # For OpenCode, we don't need to list allowed tools the same way
    # OpenCode uses tools: object with true/false values
    # By default, all tools are available, so we mostly just need to handle restrictions
    echo "$tools"
}

# Function to process a command file for Claude Code
process_command_claude() {
    local src_file="$1"
    local dest_file="$2"
    local filename=$(basename "$src_file")
    
    # Read the source file
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    # {{PLATFORM_CONFIG_DIR}} -> .claude
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.claude/g')
    
    # {{PLATFORM_NAME}} -> Claude Code
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/Claude Code/g')
    
    # Replace model references
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/opus/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/sonnet/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/haiku/g')
    
    # Replace agent references (Claude uses colons)
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan:exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan:review/g')
    
    # Replace exit command
    content=$(echo "$content" | sed 's/{{EXIT_COMMAND}}/\/exit/g')
    
    echo "$content" > "$dest_file"
}

# Function to process a command file for OpenCode
process_command_opencode() {
    local src_file="$1"
    local dest_file="$2"
    local filename=$(basename "$src_file")
    
    # Read the source file
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    # {{PLATFORM_CONFIG_DIR}} -> .opencode
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.opencode/g')
    
    # {{PLATFORM_NAME}} -> OpenCode
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/OpenCode/g')
    
    # Replace model references with OpenCode format
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/anthropic\/claude-sonnet-4-20250514/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/anthropic\/claude-sonnet-4-20250514/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/anthropic\/claude-haiku-4-20250514/g')
    
    # Replace agent references (OpenCode uses hyphens)
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan-exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan-review/g')
    
    # Replace exit command
    content=$(echo "$content" | sed 's/{{EXIT_COMMAND}}/quit/g')
    
    # Convert frontmatter format
    # allowed-tools -> tools (OpenCode format)
    # argument-hint is removed for OpenCode
    
    # Extract and transform frontmatter
    local in_frontmatter=false
    local frontmatter_done=false
    local in_tools_list=false
    local transformed=""
    local frontmatter_content=""
    local body_content=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]] && [[ "$frontmatter_done" == false ]]; then
            if [[ "$in_frontmatter" == false ]]; then
                in_frontmatter=true
                frontmatter_content="---"$'\n'
            else
                in_frontmatter=false
                frontmatter_done=true
                frontmatter_content+="---"$'\n'
            fi
        elif [[ "$in_frontmatter" == true ]]; then
            # Transform frontmatter lines
            # Skip argument-hint for OpenCode
            if [[ "$line" =~ ^argument-hint: ]]; then
                continue
            fi
            # Skip allowed-tools and its list items for OpenCode
            # OpenCode doesn't use allowed-tools in the same way
            if [[ "$line" =~ ^allowed-tools: ]]; then
                in_tools_list=true
                continue
            fi
            # Skip tool list items (lines starting with "  - ")
            if [[ "$in_tools_list" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                    continue
                else
                    in_tools_list=false
                fi
            fi
            frontmatter_content+="$line"$'\n'
        else
            body_content+="$line"$'\n'
        fi
    done <<< "$content"
    
    echo -n "${frontmatter_content}${body_content}" > "$dest_file"
}

# Function to process an agent file for Claude Code
process_agent_claude() {
    local src_file="$1"
    local dest_file="$2"
    
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.claude/g')
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/Claude Code/g')
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/opus/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/sonnet/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/haiku/g')
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan:exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan:review/g')
    
    echo "$content" > "$dest_file"
}

# Function to process an agent file for OpenCode
process_agent_opencode() {
    local src_file="$1"
    local dest_file="$2"
    
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.opencode/g')
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/OpenCode/g')
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/anthropic\/claude-sonnet-4-20250514/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/anthropic\/claude-sonnet-4-20250514/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/anthropic\/claude-haiku-4-20250514/g')
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan-exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan-review/g')
    
    # Transform agent frontmatter for OpenCode
    # Claude: name, description, tools, model, color
    # OpenCode: description, mode, model, tools (object), temperature, etc.
    
    local in_frontmatter=false
    local frontmatter_done=false
    local transformed=""
    local name=""
    local description=""
    local tools=""
    local model=""
    local body_content=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]] && [[ "$frontmatter_done" == false ]]; then
            if [[ "$in_frontmatter" == false ]]; then
                in_frontmatter=true
            else
                in_frontmatter=false
                frontmatter_done=true
            fi
        elif [[ "$in_frontmatter" == true ]]; then
            if [[ "$line" =~ ^name:\ (.+)$ ]]; then
                name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^description:\ (.+)$ ]]; then
                description="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^tools:\ (.+)$ ]]; then
                tools="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^model:\ (.+)$ ]]; then
                model="${BASH_REMATCH[1]}"
            fi
            # Skip color - not used in OpenCode
        else
            body_content+="$line"$'\n'
        fi
    done <<< "$content"
    
    # Build OpenCode frontmatter
    local opencode_frontmatter="---"$'\n'
    opencode_frontmatter+="description: $description"$'\n'
    opencode_frontmatter+="mode: subagent"$'\n'
    opencode_frontmatter+="model: $model"$'\n'
    opencode_frontmatter+="---"$'\n'
    
    echo -n "${opencode_frontmatter}${body_content}" > "$dest_file"
}

# Function to rename file for platform
rename_for_platform() {
    local filename="$1"
    local platform="$2"
    
    if [[ "$platform" == "opencode" ]]; then
        # OpenCode doesn't support colons in filenames - replace with hyphens
        echo "$filename" | sed 's/:/-/g'
    else
        echo "$filename"
    fi
}

# Process commands
echo -e "${YELLOW}Processing commands...${NC}"
for src_file in "$SRC_DIR/commands"/*.md; do
    [[ -e "$src_file" ]] || continue
    filename=$(basename "$src_file")
    
    # Claude Code
    claude_filename=$(rename_for_platform "$filename" "claude")
    process_command_claude "$src_file" "$DIST_DIR/claude/commands/$claude_filename"
    echo -e "  ${GREEN}✓${NC} Claude: $claude_filename"
    
    # OpenCode
    opencode_filename=$(rename_for_platform "$filename" "opencode")
    process_command_opencode "$src_file" "$DIST_DIR/opencode/commands/$opencode_filename"
    echo -e "  ${GREEN}✓${NC} OpenCode: $opencode_filename"
done

# Process agents
echo -e "${YELLOW}Processing agents...${NC}"
for src_file in "$SRC_DIR/agents"/*.md; do
    [[ -e "$src_file" ]] || continue
    filename=$(basename "$src_file")
    
    # Claude Code
    claude_filename=$(rename_for_platform "$filename" "claude")
    process_agent_claude "$src_file" "$DIST_DIR/claude/agents/$claude_filename"
    echo -e "  ${GREEN}✓${NC} Claude: $claude_filename"
    
    # OpenCode
    opencode_filename=$(rename_for_platform "$filename" "opencode")
    process_agent_opencode "$src_file" "$DIST_DIR/opencode/agents/$opencode_filename"
    echo -e "  ${GREEN}✓${NC} OpenCode: $opencode_filename"
done

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "Output directories:"
echo "  - Claude Code: $DIST_DIR/claude/"
echo "  - OpenCode:    $DIST_DIR/opencode/"
