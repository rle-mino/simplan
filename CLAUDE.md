# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Simplan is a structured workflow framework for **Claude Code** and **OpenCode** designed for **fast engineering, not vibe coding**. It's built for developers managing production code with serious quality concerns.

**Core principles:**
- **Optimized context** — Sub-agents handle execution and review with focused, minimal context
- **Bisect-safe commits** — Every phase leaves the codebase in a valid state
- **Plans stay local** — `.simplan/` is gitignored; plans are personal working notes, not project documentation
- **Reviewable chunks** — Work is broken into focused phases that can be understood in isolation

This is not a traditional software project—it's a collection of **markdown command/agent templates** that extend AI coding assistant capabilities.

## Architecture

```
simplan/
├── src/                    # Source templates (platform-agnostic)
│   ├── commands/           # Command templates with {{PLACEHOLDER}} syntax
│   │   ├── item:add.md
│   │   ├── item:plan.md
│   │   ├── item:brainstorm.md
│   │   ├── item:exec.md
│   │   └── ...
│   └── agents/             # Agent templates
│       ├── simplan:exec.md
│       └── simplan:review.md
├── dist/                   # Generated platform-specific files (gitignored)
│   ├── claude/             # Files for Claude Code
│   │   ├── commands/
│   │   └── agents/
│   └── opencode/           # Files for OpenCode
│       ├── commands/
│       └── agents/
├── build.sh                # Generates dist/ from src/
├── install.sh              # Installs for Claude Code or OpenCode
├── examples/               # Example ITEMS.md format
└── VERSION                 # Current version number
```

### Build System

The project uses a template system to support multiple platforms:

1. **Source templates** (`src/`) use placeholders like:
   - `{{PLATFORM_CONFIG_DIR}}` → `.claude` or `.opencode`
   - `{{PLATFORM_NAME}}` → `Claude Code` or `OpenCode`
   - `{{MODEL:opus}}` → `opus` (Claude) or `anthropic/claude-sonnet-4-20250514` (OpenCode)
   - `{{AGENT:exec}}` → `simplan:exec` (Claude) or `simplan-exec` (OpenCode)
   - `{{EXIT_COMMAND}}` → `/exit` (Claude) or `quit` (OpenCode)

2. **Build script** (`build.sh`) transforms templates into platform-specific files in `dist/`

3. **Install script** (`install.sh`) copies the appropriate `dist/` files to the user's config directory

### Key Differences Between Platforms

| Aspect | Claude Code | OpenCode |
|--------|-------------|----------|
| Config dir | `.claude/` | `.opencode/` |
| Command names | `item:add` | `item-add` |
| Agent names | `simplan:exec` | `simplan-exec` |
| Model format | `opus`, `sonnet`, `haiku` | `anthropic/claude-sonnet-4-20250514` |
| Frontmatter | `allowed-tools:` (list) | `tools:` (object) |
| Agent mode | Not explicit | `mode: subagent` |

### Key Concepts

- **Commands** (`src/commands/*.md`): Define skills invoked via `/item:*` (Claude) or `/item-*` (OpenCode). Each has YAML frontmatter specifying `description`, `argument-hint`, and `allowed-tools`.
- **Agents** (`src/agents/*.md`): Specialized prompts for delegation via the Task tool. Frontmatter defines `name`, `description`, `tools`, `model`, and `color`.
- **ITEMS.md**: User's backlog file at `.simplan/ITEMS.md` tracking work items and statuses.
- **Plans**: Markdown files at `.simplan/plans/<number>-<slug>.md` with phased execution details.

### Workflow States

```
BACKLOG → PLANNED → IN_PROGRESS ↔ IDLE → DONE
```

- Only one item can be `IN_PROGRESS` at a time
- `/item:exec` (or `/item-exec`) pauses current work and activates selected item
- Each phase must be **bisect-safe** (passes tests/lint after commit)

### Agent Collaboration Pattern

`/item:exec` orchestrates a two-agent pattern:
1. **simplan:exec / simplan-exec**: Implements the phase following the plan precisely
2. **simplan:review / simplan-review**: Reviews with "fresh eyes" (minimal context—only problem statement, not implementation details)

The reviewer can invoke the executor again to fix issues before approving.

## Development Workflow

### Building

After making changes to templates in `src/`:

```bash
./build.sh
```

This regenerates `dist/claude/` and `dist/opencode/`.

### Testing Changes

There are no automated tests. To validate changes:

1. Build the project: `./build.sh`
2. Install locally in a test project:
   ```bash
   # For Claude Code
   ./install.sh --claude
   
   # For OpenCode
   ./install.sh --opencode
   ```
3. Run through the full workflow: `/item:add` → `/item:plan` → `/item:exec` → `/item:review`
4. Test edge cases (no items, invalid numbers, etc.)

### Installation (for development)

```bash
# Global (all projects)
./install.sh --global --claude   # or --opencode

# Local (current project only)
./install.sh --claude   # or --opencode
```

Then initialize in a project:
```bash
mkdir -p .simplan/plans && touch .simplan/ITEMS.md
```

## Source Template Format

### Command Template

```markdown
---
description: Brief description for skill listing
argument-hint: [optional-args]
allowed-tools:
  - Read
  - Write
  - ...
---

## Context
@.simplan/ITEMS.md

## Task
Instructions using {{AGENT:exec}} and {{MODEL:opus}} placeholders...
```

### Agent Template

```markdown
---
name: simplan:exec
description: What this agent does
tools: Read, Write, Edit, ...
model: {{MODEL:opus}}
color: yellow
---

You are the **{{AGENT:exec}}** agent...
```

## Important Notes

- **Never edit `dist/` directly** — Always edit `src/` templates and run `./build.sh`
- **The `dist/` directory is gitignored** — It's regenerated on install
- **Colons in filenames** — Claude Code supports `item:add.md`, OpenCode requires `item-add.md`
- **Test both platforms** when making changes to ensure compatibility
