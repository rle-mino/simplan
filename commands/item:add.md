---
description: Add a new item to the backlog
argument-hint: [title]
allowed-tools:
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

## Context

Current backlog:
@.simplan/ITEMS.md

## Task

Add a new item to the backlog. Keep this lightweight - no agent delegation needed.

### Steps

1. **Read backlog**: Count existing items to determine the next item number

2. **Get details**: Use AskUserQuestion to ask for:
   - **Title**: Short, descriptive title (or use from `$ARGUMENTS` if provided)
   - **Type**: Feature or Fix
   - **Description**: What needs to be done

3. **Generate slug**: Create a URL-friendly slug from the title:
   - Lowercase the title
   - Replace spaces with hyphens
   - Remove special characters
   - Keep it short (max 30 chars)
   - Example: "Add user authentication" → "add-user-authentication"

4. **Append item**: Add to `.simplan/ITEMS.md`:

```markdown
## Item #<number>: <title>
- **Type**: <type-emoji> <Feature|Fix>
- **Status**: 📋 BACKLOG
- **Description**: <description>
- **Slug**: <slug>
- **Plan**: None
```

**Type emojis:**
- ✨ Feature
- 🐛 Fix

**Status emojis:**
- 📋 BACKLOG
- 📝 PLANNED
- 🚧 IN_PROGRESS
- ⏸️ IDLE
- ✅ DONE

5. **Confirm**: Show the added item with its number and slug

6. **Next steps**: Tell the user:
   > Item #<number> added! When you're ready to plan it, run:
   > - `/clear`
   > - `/item:plan <number>`
   > Or see all pending items with `/item:progress`
