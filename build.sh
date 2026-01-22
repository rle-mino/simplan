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

# =============================================================================
# CLAUDE CODE PROCESSING
# =============================================================================

# Process a command file for Claude Code
process_command_claude() {
    local src_file="$1"
    local dest_file="$2"
    
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.claude/g')
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/Claude Code/g')
    
    # Replace model references (Claude uses short names)
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/opus/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/sonnet/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/haiku/g')
    
    # Replace agent references (Claude uses colons)
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan:exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan:review/g')
    
    # Replace commands
    content=$(echo "$content" | sed 's/{{EXIT_COMMAND}}/\/exit/g')
    content=$(echo "$content" | sed 's/{{CLEAR_COMMAND}}/\/clear/g')
    
    # For Claude, keep allowed-tools as-is (YAML list format)
    # Transform tools list format if needed (already correct for Claude)
    
    echo "$content" > "$dest_file"
}

# Process an agent file for Claude Code
process_agent_claude() {
    local src_file="$1"
    local dest_file="$2"
    
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.claude/g')
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/Claude Code/g')
    
    # Replace model references
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/opus/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/sonnet/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/haiku/g')
    
    # Replace agent references
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan:exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan:review/g')
    
    # Replace temperature placeholders (Claude doesn't use temperature in agent config)
    # Remove temperature lines for Claude
    content=$(echo "$content" | grep -v '^temperature:')
    
    # Replace hidden placeholders (Claude doesn't use hidden)
    # Remove hidden lines for Claude
    content=$(echo "$content" | grep -v '^hidden:')
    
    # Remove permission block for Claude (not supported in same way)
    # Use awk to remove permission: block
    content=$(echo "$content" | awk '
        /^permission:/ { in_permission=1; next }
        in_permission && /^[a-z]/ { in_permission=0 }
        in_permission && /^  / { next }
        !in_permission { print }
    ')
    
    # Convert tools list format for Claude (YAML list -> comma-separated for Claude)
    # Claude uses: tools: Read, Write, Edit
    local in_frontmatter=false
    local frontmatter_done=false
    local in_tools_list=false
    local tools_collected=""
    local transformed=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]] && [[ "$frontmatter_done" == false ]]; then
            if [[ "$in_frontmatter" == false ]]; then
                in_frontmatter=true
                transformed+="$line"$'\n'
            else
                # End of frontmatter - output collected tools if any
                if [[ -n "$tools_collected" ]]; then
                    # Remove trailing comma and space
                    tools_collected="${tools_collected%, }"
                    transformed+="tools: $tools_collected"$'\n'
                fi
                in_frontmatter=false
                frontmatter_done=true
                transformed+="$line"$'\n'
            fi
        elif [[ "$in_frontmatter" == true ]]; then
            if [[ "$line" =~ ^tools:$ ]]; then
                # Start of tools list
                in_tools_list=true
            elif [[ "$in_tools_list" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]*(.+)$ ]]; then
                    # Tool item
                    local tool="${BASH_REMATCH[1]}"
                    tools_collected+="$tool, "
                else
                    # End of tools list
                    in_tools_list=false
                    transformed+="$line"$'\n'
                fi
            else
                transformed+="$line"$'\n'
            fi
        else
            transformed+="$line"$'\n'
        fi
    done <<< "$content"
    
    echo -n "$transformed" > "$dest_file"
}

# =============================================================================
# OPENCODE PROCESSING
# =============================================================================

# Process a command file for OpenCode
process_command_opencode() {
    local src_file="$1"
    local dest_file="$2"
    
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.opencode/g')
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/OpenCode/g')
    
    # Replace model references with OpenCode format (latest models)
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/anthropic\/claude-opus-4-5-20250929/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/anthropic\/claude-sonnet-4-5-20250929/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/anthropic\/claude-haiku-4-5-20250929/g')
    
    # Replace agent references (OpenCode uses hyphens)
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan-exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan-review/g')
    
    # Replace commands
    content=$(echo "$content" | sed 's/{{EXIT_COMMAND}}/quit/g')
    content=$(echo "$content" | sed 's/{{CLEAR_COMMAND}}/\/new/g')
    
    # Transform frontmatter for OpenCode
    # - Remove argument-hint (not used in OpenCode)
    # - Remove allowed-tools (OpenCode uses agent-based permissions)
    
    local in_frontmatter=false
    local frontmatter_done=false
    local in_tools_list=false
    local transformed=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]] && [[ "$frontmatter_done" == false ]]; then
            if [[ "$in_frontmatter" == false ]]; then
                in_frontmatter=true
                transformed+="$line"$'\n'
            else
                in_frontmatter=false
                frontmatter_done=true
                transformed+="$line"$'\n'
            fi
        elif [[ "$in_frontmatter" == true ]]; then
            # Skip argument-hint for OpenCode (uses $ARGUMENTS and $1, $2, etc. in body)
            if [[ "$line" =~ ^argument-hint: ]]; then
                continue
            fi
            # Skip allowed-tools and its list items for OpenCode
            if [[ "$line" =~ ^allowed-tools: ]]; then
                in_tools_list=true
                continue
            fi
            if [[ "$in_tools_list" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                    continue
                else
                    in_tools_list=false
                fi
            fi
            transformed+="$line"$'\n'
        else
            transformed+="$line"$'\n'
        fi
    done <<< "$content"
    
    echo -n "$transformed" > "$dest_file"
}

# Process an agent file for OpenCode
process_agent_opencode() {
    local src_file="$1"
    local dest_file="$2"
    
    local content=$(cat "$src_file")
    
    # Replace platform placeholders
    content=$(echo "$content" | sed 's/{{PLATFORM_CONFIG_DIR}}/.opencode/g')
    content=$(echo "$content" | sed 's/{{PLATFORM_NAME}}/OpenCode/g')
    
    # Replace model references with OpenCode format (latest models)
    content=$(echo "$content" | sed 's/{{MODEL:opus}}/anthropic\/claude-opus-4-5-20250929/g')
    content=$(echo "$content" | sed 's/{{MODEL:sonnet}}/anthropic\/claude-sonnet-4-5-20250929/g')
    content=$(echo "$content" | sed 's/{{MODEL:haiku}}/anthropic\/claude-haiku-4-5-20250929/g')
    
    # Replace agent references (OpenCode uses hyphens)
    content=$(echo "$content" | sed 's/{{AGENT:exec}}/simplan-exec/g')
    content=$(echo "$content" | sed 's/{{AGENT:review}}/simplan-review/g')
    
    # Replace temperature placeholders
    content=$(echo "$content" | sed 's/{{TEMPERATURE:low}}/0.1/g')
    content=$(echo "$content" | sed 's/{{TEMPERATURE:balanced}}/0.3/g')
    content=$(echo "$content" | sed 's/{{TEMPERATURE:high}}/0.7/g')
    
    # Replace hidden placeholder
    content=$(echo "$content" | sed 's/{{HIDDEN:true}}/true/g')
    content=$(echo "$content" | sed 's/{{HIDDEN:false}}/false/g')
    
    # Transform agent frontmatter for OpenCode
    # - name: removed (filename is the name)
    # - description: kept
    # - model: kept (already transformed)
    # - temperature: kept (already transformed)
    # - hidden: kept (already transformed)
    # - tools: list -> object with true values
    # - permission: kept as-is (OpenCode format)
    # - color: removed (OpenCode doesn't use it)
    
    local in_frontmatter=false
    local frontmatter_done=false
    local in_tools_list=false
    local in_permission_block=false
    local permission_indent=""
    local tools_list=()
    local transformed=""
    local description=""
    local model=""
    local temperature=""
    local hidden=""
    local permission_content=""
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
            # Parse frontmatter fields
            if [[ "$line" =~ ^name:\ (.+)$ ]]; then
                # Skip name - OpenCode uses filename
                continue
            elif [[ "$line" =~ ^description:\ (.+)$ ]]; then
                description="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^model:\ (.+)$ ]]; then
                model="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^temperature:\ (.+)$ ]]; then
                temperature="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^hidden:\ (.+)$ ]]; then
                hidden="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^color:\ (.+)$ ]]; then
                # Skip color - OpenCode doesn't use it
                continue
            elif [[ "$line" =~ ^tools:$ ]]; then
                in_tools_list=true
            elif [[ "$in_tools_list" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]*(.+)$ ]]; then
                    tools_list+=("${BASH_REMATCH[1]}")
                else
                    in_tools_list=false
                    # Check if this is the start of permission block
                    if [[ "$line" =~ ^permission:$ ]]; then
                        in_permission_block=true
                        permission_content="permission:"$'\n'
                    fi
                fi
            elif [[ "$line" =~ ^permission:$ ]]; then
                in_permission_block=true
                permission_content="permission:"$'\n'
            elif [[ "$in_permission_block" == true ]]; then
                if [[ "$line" =~ ^[[:space:]] ]]; then
                    permission_content+="$line"$'\n'
                else
                    in_permission_block=false
                fi
            fi
        else
            body_content+="$line"$'\n'
        fi
    done <<< "$content"
    
    # Build OpenCode frontmatter
    transformed="---"$'\n'
    transformed+="description: $description"$'\n'
    transformed+="mode: subagent"$'\n'
    transformed+="model: $model"$'\n'
    
    if [[ -n "$temperature" ]]; then
        transformed+="temperature: $temperature"$'\n'
    fi
    
    if [[ -n "$hidden" ]]; then
        transformed+="hidden: $hidden"$'\n'
    fi
    
    # Convert tools list to OpenCode object format
    if [[ ${#tools_list[@]} -gt 0 ]]; then
        transformed+="tools:"$'\n'
        for tool in "${tools_list[@]}"; do
            # Convert tool name to lowercase for OpenCode
            local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
            transformed+="  $tool_lower: true"$'\n'
        done
    fi
    
    # Add permission block if present
    if [[ -n "$permission_content" ]]; then
        transformed+="$permission_content"
    fi
    
    transformed+="---"$'\n'
    transformed+="$body_content"
    
    echo -n "$transformed" > "$dest_file"
}

# =============================================================================
# FILE RENAMING
# =============================================================================

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

# =============================================================================
# MAIN BUILD PROCESS
# =============================================================================

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
