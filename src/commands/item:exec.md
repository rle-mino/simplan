---
description: Execute a phase of an item
argument-hint: [item-number] [--model=opus|sonnet|haiku]
allowed-tools:
  - Read
  - Write
  - Edit
  - Task
  - Bash
  - AskUserQuestion
---

## Context

Current backlog:
@.simplan/ITEMS.md

## Status Emojis

When displaying or updating item statuses, use these emojis:
- 📋 `BACKLOG` - Not yet planned
- 📝 `PLANNED` - Has a plan, ready to execute
- ⏸️ `IDLE` - Started but paused
- 🔄 `IN_PROGRESS` - Currently being worked on
- ✅ `DONE` - Completed

## Task

Execute a phase for the current item by delegating to agents.

### Arguments
- `$ARGUMENTS` may contain:
  - Item number (optional - auto-selects if not provided)
  - `--model=<model>` or `-m <model>`: opus (default), sonnet, haiku

### Steps

1. **Parse arguments**: Extract item number (optional) and model (default: opus) from `$ARGUMENTS`

2. **Select item**:
   - If item number provided: use that item (must be `PLANNED` or `IDLE`)
   - If no item number:
     - First: Look for any item with status `IN_PROGRESS` (continue it)
     - If none: Pick the first item with status `PLANNED` or `IDLE` (by item number order)
   - If no eligible items exist, tell user to run `/item:plan` first

3. **Update statuses in backlog**:
   - Move ALL `IN_PROGRESS` items to `IDLE` (started but paused)
   - Set the selected item to `IN_PROGRESS`
   - This ensures only one item is ever in progress at a time

4. **Get plan path**: Read the item's Plan path from the backlog (e.g., `.simplan/plans/1-add-auth.md`)

5. **Read the plan**: Load the plan file (or folder's main file if it's a folder)

6. **Determine next step**:
   - Parse the "Execution Steps" table from the plan (if present)
   - If no step table exists, treat each phase as its own step (backward compatibility)
   - Find the lowest step number that has incomplete phases (phases without ✅)
   - Collect ALL incomplete phases from that step

7. **Single phase vs parallel decision**:

   **If only 1 phase in the step:**
   - Proceed with single-phase execution (step 8)

   **If 2-4 phases in the step:**
   - Display the phases that could run in parallel with their titles
   - Use **AskUserQuestion**:
     - "Run all N phases in parallel (Recommended)" - runs all phases concurrently
     - "Run one at a time (start with Phase X)" - sequential execution
   - If parallel: go to step 8a
   - If sequential: go to step 8 with first phase only

8. **Execute via {{AGENT:exec}}** (single phase):

   **First, read the plan file and extract the phase content.** Then inline it into the Task prompt:

   ```
   Task(
     prompt="Execute Phase <N> of item #<X>.

     Plan file: <plan-path>

     ## Phase Content (from plan)
     <INLINE THE FULL PHASE SECTION HERE - title, tasks, files, commit message, bisect note>

     ## Item Context
     - **Title**: <item title from backlog>
     - **Description**: <item description from backlog>

     Follow your execution process:
     1. Understand the phase requirements (already provided above)
     2. Implement the changes as specified
     3. Update the plan with implementation notes
     4. Mark tasks as complete",
     subagent_type="{{AGENT:exec}}",
     model=<specified model>,
     description="Execute Phase <N> of item #<X>"
   )
   ```

   **Why inline?** The @ syntax doesn't cross Task boundaries. Inlining ensures the agent has correct context immediately without spending tokens reading files.

   After execution completes, go to step 9.

8a. **Execute via {{AGENT:exec}}** (parallel phases):

    **First, read the plan file and extract each phase's content.** Then launch up to 4 Task calls **in a single message** (parallel execution):

    ```
    Task(
      prompt="Execute Phase <N> of item #<X>.

      Plan file: <plan-path>

      ## Phase Content (from plan)
      <INLINE THE FULL PHASE SECTION HERE - title, tasks, files, commit message, bisect note>

      ## Item Context
      - **Title**: <item title from backlog>
      - **Description**: <item description from backlog>

      IMPORTANT: Other phases are running in parallel. Only modify files listed in YOUR phase.

      Follow your execution process:
      1. Understand the phase requirements (already provided above)
      2. Implement the changes as specified
      3. Update the plan with implementation notes
      4. Mark tasks as complete",
      subagent_type="{{AGENT:exec}}",
      model=<specified model>,
      description="Execute Phase <N> of item #<X>"
    )
    ```

    **Why inline?** The @ syntax doesn't cross Task boundaries. Inlining ensures each agent has its phase context immediately.

    Wait for ALL tasks to complete, then go to step 9a.

9. **Review via {{AGENT:review}}** (single phase):
   ```
   Task(
     prompt="Review Phase <N> of item #<X>.

     **Problem to solve**: <copy the phase title and objective from the plan - what needs to be done, NOT how>

     Plan file: <plan-path> (only for updating status after review)

     Review the code changes with fresh eyes. Use `git diff` to see what changed.
     Validate quality and correctness based on the problem statement alone.",
     subagent_type="{{AGENT:review}}",
     description="Review Phase <N> of item #<X>"
   )
   ```
   After review completes, go to step 10.

9a. **Review via {{AGENT:review}}** (combined review for parallel phases):
    Single review for all phases that ran in parallel:
    ```
    Task(
      prompt="Review Phases <X>, <Y>, <Z> of item #<N>.

      **Problems solved** (review ALL):
      - Phase X: <title and objective>
      - Phase Y: <title and objective>
      - Phase Z: <title and objective>

      Plan file: <plan-path> (only for updating status after review)

      Review the combined code changes with fresh eyes. Use `git diff` to see what changed.
      Validate quality and correctness for EACH problem statement.
      Mark ALL phases if approved, or identify which specific phases need work.",
      subagent_type="{{AGENT:review}}",
      description="Review Phases <X>, <Y>, <Z> of item #<N>"
    )
    ```
    After review completes, go to step 10.

10. **Confirm**: Use AskUserQuestion to ask user to confirm the changes are good

11. **Update all statuses BEFORE committing**: This MUST happen before the commit:
    - Re-read the plan file to check if all phases are complete (all have ✅)
    - If all phases done, update item status to `DONE` in the backlog (ITEMS.md)
    - Ensure the plan file has all implementation notes and checkmarks

12. **Commit**: If explicitly confirmed, create **one commit per phase** (even for parallel execution):
    - For each phase in the step:
      - Stage ONLY the code files modified during that phase (listed in the phase's "Files" section)
      - Do NOT stage `.simplan/` files (they are gitignored)
      - Create commit with the phase's suggested commit message
    - Do NOT use `git add -A` or `git add .` - explicitly add only the code files from each phase

---

## Next Steps

If there are remaining phases, tell the user:

> Step complete!
>
> To continue with the next step, run:
> `/item:exec`
>
> Tip: Run `/clear` to reset context before the next step.
