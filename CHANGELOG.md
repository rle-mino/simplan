# Changelog

All notable changes to Simplan will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-01-21

### Changed

- Global install no longer modifies `.gitignore` (since it runs outside project directories)
- Global install now displays instructions for adding `.simplan/` to each project's `.gitignore`

## [1.0.2] - 2026-01-21

### Added

- Install script now automatically adds `.simplan/` to `.gitignore` (or creates one if in a git repo)

### Changed

- Documentation now clarifies that `.simplan/` should not be committed to version control

## [1.0.1] - 2026-01-21

### Fixed

- Fixed syntax error in `install.sh` line 63 that caused installation to fail when piping from curl (removed invalid `2>/dev/null` redirection from for loop)

## [1.0.0] - 2025-01-20

### Added

- `/item:add` - Add new items to the backlog
- `/item:plan` - Interactive planning with 1-12 questions
- `/item:brainstorm` - Extensive brainstorming with 10-40 questions
- `/item:exec` - Phase-by-phase execution with review
- `/item:validate` - Complete and validate items
- `/item:progress` - View backlog status
- `/item:delete` - Remove items from backlog
- `/item:help` - Workflow documentation
- `/item:updatesimplan` - Update framework and initialize .simplan/
- `simplan:exec` agent - Implements code changes following the plan
- `simplan:review` agent - Reviews changes with fresh eyes
- Auto-cleanup of deprecated simplan files on update
- XDG Base Directory spec compliance for global installs

### Installation

Global installs now use XDG-compliant paths:
- Source files: `${XDG_CONFIG_HOME:-$HOME/.config}/simplan-source/`
- Symlinks: `~/.claude/commands/` and `~/.claude/agents/`

The installer automatically removes deprecated simplan files (matching `item:*.md` for commands and `simplan:*.md` for agents) that no longer exist in the new version.
