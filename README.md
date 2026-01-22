# Simplan

A structured workflow framework for **Claude Code** and **OpenCode** that helps you plan and execute code changes through atomic, reviewable phases.

## Philosophy

**Simplan is for fast engineering, not vibe coding.**

This framework is designed for developers managing production code with serious quality concerns—code that will be reviewed, deployed, and maintained. It's not for throwaway prototypes or experiments where "just make it work" is acceptable.

### Why Simplan exists

AI coding assistants are powerful, but without structure they can produce sprawling changes that are hard to review, test, and debug. Simplan addresses this by:

1. **Optimizing context usage** — Sub-agents handle execution and review with focused, minimal context. The executor knows only the current phase; the reviewer sees only the problem statement, not implementation details. This "fresh eyes" approach catches issues that the implementer might miss.

2. **Enforcing bisect-safe commits** — Every phase must leave the codebase in a valid state (tests pass, linting clean). When bugs appear later, `git bisect` can pinpoint exactly which change introduced them.

3. **Keeping plans local** — The `.simplan/` directory is automatically gitignored. Plans are your personal working notes—they track *your* thought process, not project documentation. Nobody in your organization wants to review these files. If something needs to be shared, add proper documentation to the project itself.

4. **Breaking work into reviewable chunks** — Instead of one massive commit touching 20 files, you get focused phases that can be understood and reviewed in isolation.

### Who this is for

- Developers working on production codebases
- Teams that do code review
- Projects where quality and maintainability matter
- Anyone who's been burned by "it worked when I tested it" commits

### Who this is NOT for

- Quick prototypes where you'll throw away the code
- Learning projects where experimentation is the goal
- Situations where you just need something working *right now*

## Supported Platforms

Simplan works with both:

| Platform | Config Directory | Command Style |
|----------|------------------|---------------|
| **Claude Code** | `.claude/` | `/item:add`, `/item:plan`, etc. |
| **OpenCode** | `.opencode/` | `/item-add`, `/item-plan`, etc. |

The installer auto-detects your platform or lets you choose.

## Overview

Simplan transforms how you work with AI coding assistants by adding a structured backlog and phased execution workflow:

```
BACKLOG → PLANNED →  IN_PROGRESS  →  DONE
   ↑         ↑           ↑     ↓      ↑
 /add      /plan       /exec   ↔  IDLE /review
         /brainstorm
```

**Key Features:**

- **Backlog management** - Track work items with clear statuses

- **Interactive planning** - Break work into atomic, committable phases through focused Q&A (1-12 questions with `/item:plan` or `/item-plan`)

- **Deep brainstorming** - For complex or ambiguous items, `/item:brainstorm` (or `/item-brainstorm`) conducts extensive exploration (10-40 questions) covering requirements, UX, technical approach, edge cases, security, and more

- **Phased execution** - Execute one phase at a time with automatic review

- **Bisect-safe commits** - Every phase leaves the codebase in a valid state

**Two Planning Modes:**

| Mode | Questions | Best For |
|------|-----------|----------|
| `/item:plan` | 1-12 (quick) | Clear, straightforward items |
| `/item:brainstorm` | 10-40 (thorough) | Complex features, unclear requirements, architectural decisions |

Brainstorm includes web research (Context7 for library docs, WebSearch for best practices) and produces a comprehensive plan with full Q&A log, research findings, and detailed phase breakdowns.

## Installation

The installer auto-detects your platform (Claude Code or OpenCode) based on existing configuration directories.

**Global install** (available in all projects):

```bash
curl -fsSL https://raw.githubusercontent.com/rle-mino/simplan/main/install.sh | bash -s -- --global
```

**Local install** (current project only):

```bash
curl -fsSL https://raw.githubusercontent.com/rle-mino/simplan/main/install.sh | bash
```

**Specify platform explicitly:**

```bash
# For Claude Code
curl -fsSL https://raw.githubusercontent.com/rle-mino/simplan/main/install.sh | bash -s -- --claude

# For OpenCode
curl -fsSL https://raw.githubusercontent.com/rle-mino/simplan/main/install.sh | bash -s -- --opencode
```

Then initialize simplan in your project:

```bash
mkdir -p .simplan/plans && touch .simplan/ITEMS.md
```

## Quick Start

### Claude Code

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
   /item:review 1
   ```
   Reviews all phases are complete and marks the item as done.

### OpenCode

1. **Add a work item:**
   ```
   /item-add
   ```

2. **Plan the item:**
   ```
   /item-plan 1
   ```

3. **Execute phases:**
   ```
   /item-exec
   ```

4. **Complete the item:**
   ```
   /item-review 1
   ```

## Commands

| Claude Code | OpenCode | Description |
|-------------|----------|-------------|
| `/item:add` | `/item-add` | Add a new item to the backlog |
| `/item:plan [number]` | `/item-plan [number]` | Plan an item with 1-12 questions |
| `/item:brainstorm [number]` | `/item-brainstorm [number]` | Brainstorm extensively (10-40 questions) before planning |
| `/item:exec [number]` | `/item-exec [number]` | Execute the next phase of an item |
| `/item:review [number]` | `/item-review [number]` | Review and complete an item |
| `/item:progress` | `/item-progress` | Show next 20 backlog items (not DONE) |
| `/item:delete [number]` | `/item-delete [number]` | Remove an item from the backlog |
| `/item:prune` | `/item-prune` | Remove all completed (DONE) items |
| `/item:help` | `/item-help` | Show workflow documentation |
| `/item:updatesimplan` | `/item-updatesimplan` | Update simplan to the latest version |

### `/item:add` / `/item-add`

Adds a new work item to the backlog. The assistant will ask you for:

- **Title** - Short description of the work
- **Type** - Feature, Fix, Refactor, Docs, or Test
- **Description** - Detailed explanation of what needs to be done

The item is created with status `BACKLOG` and assigned the next available number.

### `/item:plan` / `/item-plan`

Creates a phased execution plan for an item through focused Q&A (1-12 questions across up to 3 rounds).

**Process:**
1. Explores your codebase to understand context
2. Asks clarifying questions about requirements and approach
3. Creates atomic phases, each with tasks, files, and commit messages
4. Updates item status to `PLANNED`

If no number is provided, shows available items and asks which to plan.

### `/item:brainstorm` / `/item-brainstorm`

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

### `/item:exec` / `/item-exec`

Executes the next incomplete phase of an item. Uses two specialized agents:

1. **simplan:exec / simplan-exec** - Implements the phase following the plan precisely
2. **simplan:review / simplan-review** - Reviews changes, validates quality, can request fixes

**Process:**
1. Finds the next incomplete phase
2. Executor implements the changes
3. Reviewer validates the work
4. If issues found, executor fixes them
5. Commits the phase with the planned commit message
6. Updates phase checkboxes and progress

### `/item:review` / `/item-review`

Reviews that all phases of an item are complete and marks it as `DONE`.

**Checks:**
- All phase checkboxes are marked `[x]`
- Plan progress shows completion
- No remaining work

If review fails, shows what's incomplete.

### `/item:progress` / `/item-progress`

Shows the next 20 backlog items that are not `DONE`. Displays:

- Item number and title
- Current status (with emoji)
- Type (Feature/Fix/etc.)
- Progress for planned items (e.g., "2/5 phases")

### `/item:delete` / `/item-delete`

Removes an item from the backlog. Also deletes the associated plan file if one exists.

Asks for confirmation before deleting. If no number provided, shows available items.

### `/item:prune` / `/item-prune`

Removes all completed (`DONE`) items from the backlog in one operation. Useful for cleaning up after finishing multiple items.

**Process:**
1. Lists all DONE items that will be removed
2. Asks for confirmation
3. Deletes associated plan files
4. Removes items from backlog
5. Renumbers remaining items to keep them sequential

### `/item:help` / `/item-help`

Displays comprehensive documentation about the simplan workflow, including:

- Available commands
- Item statuses and transitions
- Planning vs brainstorming guidance
- Best practices

### `/item:updatesimplan` / `/item-updatesimplan`

Updates simplan framework files (commands, agents) to the latest version from the repository.

**What it does:**
- Detects your installation mode (global vs local)
- Downloads and installs the latest version
- Shows version change (e.g., "1.0.0 → 1.1.0")

**What it does NOT touch:**
- Your project data (`.simplan/ITEMS.md`, `.simplan/plans/`)
- Any work items or plans you've created

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

> **Note:** The `.simplan/` directory is for local planning only and should **not** be committed to version control. The installer automatically adds it to `.gitignore`.

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

### Planning vs Brainstorming

Use `/item:plan` (or `/item-plan`) for:
- Straightforward features with clear requirements
- Bug fixes with known scope
- Small refactoring tasks

Use `/item:brainstorm` (or `/item-brainstorm`) for:
- Complex features with unclear requirements
- Architectural decisions
- Features that touch many parts of the codebase
- Items where you're not sure how to approach the problem

### The Two-Agent Pattern

Simplan uses specialized sub-agents to optimize context and catch mistakes:

- **simplan:exec / simplan-exec** — Implements a single phase following the plan precisely. It sees only the current phase, keeping context focused.
- **simplan:review / simplan-review** — Reviews changes with "fresh eyes." It receives only the problem statement and the diff, not the implementation details. This separation helps catch issues the implementer might overlook.

The agents work as a pair: execute → review → fix if needed → commit. This mimics a real code review workflow, but faster.

## Development

For contributors working on simplan itself:

### Building

The project uses a build system to generate platform-specific files from source templates:

```bash
./build.sh
```

This generates:
- `dist/claude/` - Files for Claude Code
- `dist/opencode/` - Files for OpenCode

### Source Structure

```
simplan/
├── src/
│   ├── commands/         # Command templates with {{PLACEHOLDER}} syntax
│   └── agents/           # Agent templates
├── dist/                 # Generated platform-specific files (gitignored)
│   ├── claude/
│   └── opencode/
├── build.sh              # Build script
├── install.sh            # Installation script
└── examples/             # Example ITEMS.md format
```

### Template Placeholders

- `{{PLATFORM_CONFIG_DIR}}` → `.claude` or `.opencode`
- `{{PLATFORM_NAME}}` → `Claude Code` or `OpenCode`
- `{{AGENT:exec}}` → `simplan:exec` or `simplan-exec`
- `{{EXIT_COMMAND}}` → `/exit` or `quit`

## Best Practices

1. **Plan before coding** - Always run `/item:plan` or `/item:brainstorm` before `/item:exec`
2. **Keep phases small** - Prefer many small phases over few large ones
3. **One item at a time** - Complete an item before starting another
4. **Review each phase** - Don't rush through phases; review changes before committing
5. **Bisect compliance** - Every phase must leave the codebase in a valid state

## License

MIT - see [LICENSE](LICENSE)
