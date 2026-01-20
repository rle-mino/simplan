# Simplan

A structured workflow framework for Claude Code that helps you plan and execute code changes through atomic, reviewable phases.

## Overview

Simplan transforms how you work with Claude Code by adding a structured backlog and phased execution workflow:

```
BACKLOG → PLANNED →  IN_PROGRESS  →  DONE
   ↑         ↑           ↑     ↓      ↑
 /add      /plan       /exec   ↔  IDLE /validate
         /brainstorm
```

**Key Features:**

- **Backlog management** - Track work items with clear statuses

- **Interactive planning** - Break work into atomic, committable phases through focused Q&A (1-12 questions with `/item:plan`)

- **Deep brainstorming** - For complex or ambiguous items, `/item:brainstorm` conducts extensive exploration (10-40 questions) covering requirements, UX, technical approach, edge cases, security, and more

- **Phased execution** - Execute one phase at a time with automatic review

- **Bisect-safe commits** - Every phase leaves the codebase in a valid state

**Two Planning Modes:**

| Mode | Questions | Best For |
|------|-----------|----------|
| `/item:plan` | 1-12 (quick) | Clear, straightforward items |
| `/item:brainstorm` | 10-40 (thorough) | Complex features, unclear requirements, architectural decisions |

Superplan includes web research (Context7 for library docs, WebSearch for best practices) and produces a comprehensive plan with full Q&A log, research findings, and detailed phase breakdowns.

## Installation

**Global install** (available in all projects):

```bash
curl -fsSL https://raw.githubusercontent.com/rle-mino/simplan/main/install.sh | bash -s -- --global
```

**Local install** (current project only):

```bash
curl -fsSL https://raw.githubusercontent.com/rle-mino/simplan/main/install.sh | bash
```

Then initialize simplan in your project:

```bash
mkdir -p .simplan/plans && touch .simplan/ITEMS.md
```

## Quick Start

1. **Add a work item:**
   ```
   /item:add
   ```
   Claude will ask for a title, type (Feature/Fix), and description.

2. **Plan the item:**
   ```
   /item:plan 1
   ```
   Claude explores your codebase, asks clarifying questions, and creates a phased plan.

3. **Execute phases:**
   ```
   /item:exec
   ```
   Claude executes one phase at a time, reviews the changes, and commits.

4. **Complete the item:**
   ```
   /item:validate 1
   ```
   Verifies all phases are complete and marks the item as done.

## Commands

| Command | Description |
|---------|-------------|
| `/item:add` | Add a new item to the backlog |
| `/item:plan [number]` | Plan an item with 1-12 questions |
| `/item:brainstorm [number]` | Brainstorm extensively (10-40 questions) before planning |
| `/item:exec [number]` | Execute the next phase of an item |
| `/item:validate [number]` | Validate and complete an item |
| `/item:progress` | Show next 20 backlog items (not DONE) |
| `/item:delete [number]` | Remove an item from the backlog |
| `/item:help` | Show workflow documentation |
| `/item:update` | Update simplan to the latest version |

### `/item:add`

Adds a new work item to the backlog. Claude will ask you for:

- **Title** - Short description of the work
- **Type** - Feature, Fix, Refactor, Docs, or Test
- **Description** - Detailed explanation of what needs to be done

The item is created with status `BACKLOG` and assigned the next available number.

```
/item:add
```

### `/item:plan [number]`

Creates a phased execution plan for an item through focused Q&A (1-12 questions across up to 3 rounds).

**Process:**
1. Explores your codebase to understand context
2. Asks clarifying questions about requirements and approach
3. Creates atomic phases, each with tasks, files, and commit messages
4. Updates item status to `PLANNED`

If no number is provided, shows available items and asks which to plan.

```
/item:plan 1
```

### `/item:brainstorm [number]`

Conducts extensive brainstorming (10-40 questions) before creating a comprehensive plan. Use this for complex or ambiguous items.

**Process:**
1. Deep codebase exploration
2. Web research (library docs via Context7, best practices via WebSearch)
3. Extensive Q&A covering:
   - Requirements & goals
   - User experience
   - Technical approach
   - Edge cases & error handling
   - Integration & dependencies
   - Testing & quality
   - Scope & priorities
   - Security & compliance
   - Operations & maintenance
   - Risks & unknowns
4. Validates understanding with you
5. Creates detailed plan with full Q&A log and research findings

```
/item:brainstorm 1
```

### `/item:exec [number]`

Executes the next incomplete phase of an item. Uses two specialized agents:

1. **simplexecutor** - Implements the phase following the plan precisely
2. **simpreviewer** - Reviews changes, validates quality, can request fixes

**Process:**
1. Finds the next incomplete phase
2. Executor implements the changes
3. Reviewer validates the work
4. If issues found, executor fixes them
5. Commits the phase with the planned commit message
6. Updates phase checkboxes and progress

Supports `--model=opus|sonnet|haiku` to specify which model to use.

```
/item:exec
/item:exec 1
/item:exec --model=haiku
```

### `/item:validate [number]`

Validates that all phases of an item are complete and marks it as `DONE`.

**Checks:**
- All phase checkboxes are marked `[x]`
- Plan progress shows completion
- No remaining work

If validation fails, shows what's incomplete.

```
/item:validate 1
```

### `/item:progress`

Shows the next 20 backlog items that are not `DONE`. Displays:

- Item number and title
- Current status (with emoji)
- Type (Feature/Fix/etc.)
- Progress for planned items (e.g., "2/5 phases")

```
/item:progress
```

### `/item:delete [number]`

Removes an item from the backlog. Also deletes the associated plan file if one exists.

Asks for confirmation before deleting. If no number provided, shows available items.

```
/item:delete 3
```

### `/item:help`

Displays comprehensive documentation about the simplan workflow, including:

- Available commands
- Item statuses and transitions
- Planning vs brainstorming guidance
- Best practices

```
/item:help
```

### `/item:update`

Updates simplan framework files (commands, agents) to the latest version from the repository.

**What it does:**
- Detects your installation mode (global vs local)
- Downloads and installs the latest version
- Shows version change (e.g., "1.0.0 → 1.1.0")

**What it does NOT touch:**
- Your project data (`.simplan/ITEMS.md`, `.simplan/plans/`)
- Any work items or plans you've created

```
/item:update
```

## Item Statuses

| Status | Emoji | Description |
|--------|-------|-------------|
| BACKLOG | 📋 | Work identified, not yet planned |
| PLANNED | 📝 | Plan created, ready to execute |
| IN_PROGRESS | 🔄 | Currently being worked on |
| IDLE | ⏸️ | Started but paused |
| DONE | ✅ | All phases completed |

## File Structure

Simplan uses a `.simplan` directory in your project root:

```
.simplan/
├── ITEMS.md                    # Backlog with all items and statuses
└── plans/
    ├── 1-add-auth.md           # Simple plan (single file)
    └── 2-refactor-api/         # Extensive plan (folder)
        ├── README.md           # Plan overview
        ├── brainstorm.md       # Full Q&A log (from /item:brainstorm)
        ├── phase-1.md          # Phase 1 details
        └── phase-2.md          # Phase 2 details
```

### ITEMS.md Format

```markdown
## Item #1: Add user authentication
- **Type**: Feature
- **Status**: PLANNED
- **Description**: Implement login/logout with session management
- **Slug**: add-user-authentication
- **Plan**: .simplan/plans/1-add-user-authentication.md
```

### Plan File Format

```markdown
# Plan: Item #1 - Add user authentication

## Context
<What was learned about the codebase>

## Clarifications
<Questions asked and answers received>

## Phases

### Phase 1: Create auth middleware
- [ ] Create middleware file
- [ ] Add session validation logic
- **Files**: src/middleware/auth.ts
- **Commit message**: `feat(auth): add authentication middleware`
- **Bisect note**: N/A

### Phase 2: Add login endpoint
- [ ] Create login route
- [ ] Implement credential validation
- **Files**: src/routes/auth.ts
- **Commit message**: `feat(auth): add login endpoint`
- **Bisect note**: Depends on middleware from Phase 1

## Current Status
- **Current Phase**: Not started
- **Progress**: 0/2
```

## Workflow Philosophy

### Why Phases?

Breaking work into phases provides:

1. **Reviewable chunks** - Each phase is small enough to review thoroughly
2. **Safe checkpoints** - Every commit passes tests and linting
3. **Bisect compatibility** - If a bug appears, git bisect can find it
4. **Progress visibility** - Clear tracking of what's done vs remaining

### Planning vs Superplanning

Use `/item:plan` for:
- Straightforward features with clear requirements
- Bug fixes with known scope
- Small refactoring tasks

Use `/item:brainstorm` for:
- Complex features with unclear requirements
- Architectural decisions
- Features that touch many parts of the codebase
- Items where you're not sure how to approach the problem

### Agents

Simplan uses two specialized agents:

- **simplexecutor** - Implements a single phase following the plan precisely
- **simpreviewer** - Reviews changes with fresh eyes, validates quality

The executor and reviewer work as a pair: execute, review, fix if needed, commit.

## Best Practices

1. **Plan before coding** - Always run `/item:plan` or `/item:brainstorm` before `/item:exec`
2. **Keep phases small** - Prefer many small phases over few large ones
3. **One item at a time** - Complete an item before starting another
4. **Review each phase** - Don't rush through phases; review changes before committing
5. **Bisect compliance** - Every phase must leave the codebase in a valid state

## License

MIT - see [LICENSE](LICENSE)
