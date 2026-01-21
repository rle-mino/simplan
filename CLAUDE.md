# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Simplan is a structured workflow framework for Claude Code designed for **fast engineering, not vibe coding**. It's built for developers managing production code with serious quality concerns.

**Core principles:**
- **Optimized context** — Sub-agents handle execution and review with focused, minimal context
- **Bisect-safe commits** — Every phase leaves the codebase in a valid state
- **Plans stay local** — `.simplan/` is gitignored; plans are personal working notes, not project documentation
- **Reviewable chunks** — Work is broken into focused phases that can be understood in isolation

This is not a traditional software project—it's a collection of **markdown command files** and **agent definitions** that extend Claude Code's capabilities.

## Architecture

```
simplan/
├── commands/           # Skill definitions (item:*.md)
│   ├── item:add.md     # Add work items to backlog
│   ├── item:plan.md    # Create phased plans (1-12 questions)
│   ├── item:brainstorm.md  # Deep planning (10-40 questions)
│   ├── item:exec.md    # Execute phases via agents
│   ├── item:review.md      # Review and complete items
│   ├── item:prune.md   # Remove all DONE items
│   └── ...
├── agents/             # Specialized agent prompts
│   ├── simplan:exec.md     # Implements code changes
│   └── simplan:review.md   # Reviews changes with fresh eyes
├── examples/           # Example ITEMS.md format
└── install.sh          # Installer (local or global)
```

### Key Concepts

- **Commands** (`commands/*.md`): Define skills invoked via `/item:*`. Each has YAML frontmatter specifying `description`, `argument-hint`, and `allowed-tools`.
- **Agents** (`agents/*.md`): Specialized prompts for delegation via the Task tool. Frontmatter defines `name`, `description`, `tools`, `model`, and `color`.
- **ITEMS.md**: User's backlog file at `.simplan/ITEMS.md` tracking work items and statuses.
- **Plans**: Markdown files at `.simplan/plans/<number>-<slug>.md` with phased execution details.

### Workflow States

```
BACKLOG → PLANNED → IN_PROGRESS ↔ IDLE → DONE
```

- Only one item can be `IN_PROGRESS` at a time
- `/item:exec` pauses current work and activates selected item
- Each phase must be **bisect-safe** (passes tests/lint after commit)

### Agent Collaboration Pattern

`/item:exec` orchestrates a two-agent pattern:
1. **simplan:exec**: Implements the phase following the plan precisely
2. **simplan:review**: Reviews with "fresh eyes" (minimal context—only problem statement, not implementation details)

The reviewer can invoke simplan:exec again to fix issues before approving.

## Installation

```bash
# Global (all projects)
./install.sh --global

# Local (current project only)
./install.sh
```

Then initialize in a project:
```bash
mkdir -p .simplan/plans && touch .simplan/ITEMS.md
```

## Testing Changes

There are no automated tests. To validate changes:
1. Install locally in a test project
2. Run through the full workflow: `/item:add` → `/item:plan` → `/item:exec` → `/item:review`
3. Test edge cases (no items, invalid numbers, etc.)

## Command File Format

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
Instructions for Claude...
```

## Agent File Format

```markdown
---
name: agentname
description: What this agent does
tools: Read, Write, Edit, ...
model: opus|sonnet|haiku
color: yellow|green|...
---

Agent prompt instructions...
```
