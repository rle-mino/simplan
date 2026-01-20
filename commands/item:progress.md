---
description: Show next 20 backlog items (not DONE)
allowed-tools:
  - Read
---

## Task

Show a concise progress view of up to 20 items that are not DONE.

### Steps

1. **Read backlog**: Read `.simplan/ITEMS.md`

2. **Filter items**:
   - Extract items where Status is NOT `DONE` (include BACKLOG, PLANNED, IDLE, IN_PROGRESS)
   - If fewer than 20 non-DONE items, fill remaining slots with DONE items (most recent first)

3. **Take first 20**: Limit to 20 total items

4. **Get phase progress**: For PLANNED, IDLE, or IN_PROGRESS items, read the plan file to count completed phases (checkboxes `[x]`) vs total phases

5. **Display as table**:

```
| #  | Item                              | Phases | Status      |
|----|-----------------------------------|--------|-------------|
| 1  | Cursor ignores markers            | 2/3    | IN_PROGRESS |
| 2  | MIDI not detected                 | 1/2    | IDLE        |
| 3  | Workflows system                  | 0/2    | PLANNED     |
| 4  | Add dark mode                     | -      | BACKLOG     |
|    |                                   |        |             |
| 5  | Fix login bug                     | 2/2    | DONE        |
```

- **Item**: Title truncated to ~30 chars
- **Phases**: `done/total` from plan, or `-` if no plan
- **Status**: BACKLOG, PLANNED, IDLE, IN_PROGRESS, DONE
- Add a blank separator row before DONE items if any are shown

If no items exist, say "No items."

6. **Next steps**: Based on what's shown, suggest the logical next action:
   - If there's an IN_PROGRESS item:
     > Continue with the current item:
     > ```
     > /item:exec
     > ```
   - If there's no IN_PROGRESS but there's a PLANNED or IDLE item:
     > Start/resume an item:
     > ```
     > /item:exec        # auto-selects first PLANNED/IDLE
     > /item:exec <num>  # or specify item number
     > ```
   - If all items are BACKLOG:
     > Plan an item before executing:
     > ```
     > /item:plan <number>
     > ```
   - If no items exist:
     > Add an item to get started:
     > ```
     > /item:add
     > ```
