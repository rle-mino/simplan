# Contributing to Simplan

Thank you for your interest in contributing to Simplan!

## Philosophy

Simplan is for **fast engineering, not vibe coding**. Contributions should support developers managing production code with serious quality concerns. Keep this in mind:

- **Context efficiency matters** — Sub-agents should receive minimal, focused context
- **Plans are personal** — `.simplan/` stays gitignored; it's working notes, not project documentation
- **Quality over convenience** — Bisect-safe commits and reviewable phases are non-negotiable

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Include clear steps to reproduce for bugs
- Describe expected vs actual behavior

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test locally using dev mode (see below)
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

### Testing Local Changes

Use the `--dev` flag to test your changes without publishing:

```bash
# From the simplan repository directory
./install.sh --dev --claude    # Test with Claude Code
./install.sh --dev --opencode  # Test with OpenCode
```

This installs from your local source instead of cloning from GitHub, allowing you to:
- Test command changes immediately
- Verify agent behavior
- Debug issues before publishing

### Code Style

- Keep command/agent files focused and well-documented
- Follow existing patterns in the codebase
- Test changes with real Claude Code sessions

### Areas for Contribution

- **Commands**: New workflow commands
- **Agents**: Improved agent prompts
- **Documentation**: Better examples and guides
- **Bug fixes**: Issues with existing commands

## Questions?

Open a GitHub Issue for any questions about contributing.
