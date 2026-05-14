# Jira sync — Capabilities 4 (push) and 6 (pull)

Designed by scrum-master defaults. Status mirrors both ways automatically (after one-time per-session opt-in), Stories carry full Definition-of-Done, Epics get optional target dates but Stories never do.

## Required tools

- `mcp__claude_ai_Atlassian_Rovo__createJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__getJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__editJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql`
- `mcp__claude_ai_Atlassian_Rovo__getTransitionsForJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__transitionJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__addCommentToJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__lookupJiraAccountId`

If the Atlassian MCP isn't connected, the skill prints the would-be `createJiraIssue` payload as JSON for manual paste.

## Project + assignee config (asked once per repo, cached in changelog)

First push to a project asks the user for project key and reporter, then resolves assignees from MASTER-PLAN owner names. Cached in `docs/plans/.roadmap-tracker-changelog.md` as a header note:

```markdown
## YYYY-MM-DD — Jira configuration set

- **Cloud:** <subdomain>.atlassian.net
- **Project key:** <KEY>
- **Default issue type for tasks:** Story
- **Reporter (Jira account):** <name> <accountId>
- **Sprint cadence:** monthly
- **Sprint naming:** `sprint-YYYY-MM` (ISO-sortable; e.g. `sprint-2026-05`, `sprint-2026-06`, `sprint-2026-07`)
- **Auto-assign new issues to current month's sprint:** yes
- **Rollover:** team-managed via Jira's "Complete Sprint → Move to next sprint" — skill does not auto-rollover
- **Board ID:** <board-id from project config>  (needed for sprint API calls)
- **Status mirroring:** auto-propagate transitions to Jira (📋 → ⏳ → ✅ + Blocked)
- **Set by:** <user>

### Assignee map (resolved via lookupJiraAccountId)

| MASTER-PLAN owner name | Jira display name | Jira account ID |
|---|---|---|
| <local name> | <jira name> | <accountId> |
```

Future invocations read from this header before prompting.

## Mapping: phase → Epic; task → Story; sprint = current month

**Sprint cadence: monthly**, named `sprint-YYYY-MM` (ISO-sortable; e.g. `sprint-2026-05`, `sprint-2026-06`). Every newly-created Epic and Story is auto-assigned to the **current month's** sprint. Incomplete tasks roll over via Jira's standard "Complete Sprint → Move to next sprint" flow at month boundary — the skill does not auto-rollover.

### Sprint resolution at create time

Before creating any issue (Epic or Story), the skill resolves the current sprint:

1. Compute current sprint name: `sprint-$(date +%Y-%m)`. So today (2026-05-14) → `sprint-2026-05`.
2. Find the sprint on the project's board. The Atlassian MCP wraps the agile API for some clouds; if available, fetch active + future sprints on the board ID and match by name.
3. **If sprint exists:** capture its sprint ID; pass to issue creation via the Sprint custom field (typically `customfield_10020`, but field ID varies — discover via `getJiraIssueTypeMetaWithFields` for the project's Story type).
4. **If sprint doesn't exist:** offer to create it via the agile API. If the MCP doesn't expose sprint create, fall back to the label workaround:
   - Add label `sprint-YYYY-MM` (e.g. `sprint-2026-05`) to every issue created in this push
   - Surface to user: "Sprint `sprint-2026-05` doesn't exist on board <ID>. I've labeled all created issues with `sprint-2026-05` instead. Create the sprint in Jira and use the bulk-add-to-sprint UI to pull these in, or pre-create the sprint and re-run this push."
5. **Stale-sprint guard** (one-time per push): if the resolved sprint name doesn't match today's `sprint-$(date +%Y-%m)` — e.g. machine clock drift, mid-month timezone edge — the skill flags it. ISO-sortable naming makes year collisions impossible (no two `sprint-2026-05` and `sprint-2027-05` overlap in the search results), so this guard is just for clock-correctness.

### Rollover at month boundary

Not auto-handled. Standard scrum-master ritual:

1. On the last working day of the month: run sprint review + retro in Jira UI.
2. Click "Complete Sprint" on the active sprint.
3. Jira prompts: where do incomplete issues go? Pick "Move to next sprint" → all incomplete issues automatically land in next month's sprint (e.g. `sprint-2026-06` after May closes), which the skill will create on next push if no manual prep.
4. For status tracking: incomplete tasks remain `⏳ In progress` or `📋 Pipeline` in MASTER-PLAN.md; their Jira sprint just changes. Capability 6 (sync from Jira) is not affected by sprint changes — it tracks status, not sprint membership.

The skill does NOT remind you to close sprints. If you want that, run `/loop monthly /roadmap-tracker close-sprint-prompt` (a future enhancement; not implemented today).

### Phase → Epic

```
Issue type:   Epic
Summary:      <PROJECT>: Phase N — <name>
Epic Name:    Phase N — <name>            (custom field where required)
Sprint:       <current month's sprint id>  (set via Sprint custom field)
              fallback: label sprint-YYYY-MM if sprint API unavailable
Labels:       roadmap, phase-N, <project-slug>
Reporter:     <from config>
Assignee:     <phase owner from MASTER-PLAN; same fallback chain as Stories>
Due date:     OPTIONAL — ask once per epic at create time:
              "Phase N target completion date? [YYYY-MM-DD or skip]"
Story points: NOT set on epics (only Stories carry points)

Description (ADF):
  ## Phase achievement target
  <pulled from MASTER-PLAN "Achievement target" paragraph>

  ## Exit criteria
  <bulleted from MASTER-PLAN "Phase N exit criteria" or spec exit checklist>

  ## Linked spec
  - docs/specs/<spec>.md  (full design)
  - docs/plans/MASTER-PLAN.md  (single source of truth)
  - docs/handoff/<handoff>.md  (if present)

  ## Phase context
  <one paragraph: why this phase, dependencies on prior phases>

  ---
  Synced from docs/plans/MASTER-PLAN.md (commit <hash>) by roadmap-tracker.
```

### Task → Story

```
Issue type:    Story (default; configurable to Task per project)
Summary:       T-N.X — <one-line title>
Epic Link:     <Epic key from above>      (custom field customfield_10014)
Sprint:        <current month's sprint id> (same Sprint custom field as Epic)
               fallback: label sprint-YYYY-MM
Labels:        roadmap, task-T-N-X, <area tag from commit convention>
Reporter:      <from config>
Assignee:      <task owner; lookup chain below>
Due date:      NEVER set (per scrum-master default — date lives on Sprint commitment, not per-task)
Story points:  From task size:
                 1pt ≈ 2h    2pt ≈ 4h    3pt ≈ 6h
                 5pt ≈ 1 day 8pt ≈ 2 days  13pt ≈ 1 week (split if >13)

Description (ADF, scrum-style):
  ## What
  <one-line task title from MASTER-PLAN row>

  ## Why (user-facing outcome)
  <pulled from the parent phase's achievement target — same line for every task in the phase, but anchors the work to user impact>

  ## Acceptance Criteria
  - [ ] <pulled from spec/handoff "Verify" steps for this task>
  - [ ] <pulled from phase exit criteria items relevant to this task>

  ## Implementation notes
  **Files:** <paths from handoff>
  **Spec ref:** <doc> §X
  **Change:** <2-4 sentences from handoff "Change" field>

  ## Definition of Done
  - [ ] Tests pass: <repo's test command, e.g. `uv run pytest`>
  - [ ] Lint clean: <repo's lint command, e.g. `uv run ruff check`>
  - [ ] Code reviewed (1+ approval)
  - [ ] Merged to main
  - [ ] Master plan updated to ✅ (auto-handled by roadmap-tracker)

  ---
  Spec: <doc path>
  Source: docs/plans/MASTER-PLAN.md (commit <hash>)
```

## Assignee resolution (the scrum-master gap-filler)

When a task has owner "npatel" or "Nilay Patel" or any name string from MASTER-PLAN, resolve to a Jira account ID via this chain:

1. **Cache hit** — if the assignee map header in changelog has this name, use the cached accountId.
2. **Direct lookup** — call `lookupJiraAccountId(<name>)`.
3. **Alternate-form lookup** — if the name is a unix-handle ("npatel"), try the full display name from project memory if known ("Nilay Patel"). Same in reverse.
4. **Search by name + email** — if the user provided an email at config time, try that.
5. **Prompt user** — show 3-5 closest matches via `searchConfluenceUsingCql` (or Jira user search), let user pick.
6. **Fallback if user skips** — leave issue unassigned, add label `needs-assignee`, flag in chat: "Story <KEY>-X created without assignee. Assign in Jira before sprint planning."

After successful resolution, write the (name → accountId) pair into the changelog assignee-map header for future pushes.

## Local status icon ↔ Jira status mapping (auto-mirrored)

Per scrum-master default: **all local transitions propagate to Jira**, not just Done. Asked once per session whether to auto-propagate; cached for the rest of the session.

| Local status | Jira status | Auto-action on local transition |
|---|---|---|
| 📋 Pipeline | `To Do` / `Backlog` | (initial state on Capability 4 create) |
| ⏳ In progress | `In Progress` | call `transitionJiraIssue` with `Start progress`; add comment "Started — taken from backlog into active work. (by <user>)" |
| ✅ Shipped | `Done` | call `transitionJiraIssue` with `Done`; add comment "Completed in commit <hash> on <date>. See PR <#N> if applicable." |
| Blocked (label) | `Blocked` (if project has it) or label `impediment` | call `editJiraIssue` to add label; add comment "Blocked: <reason from local note>" |

Discover transition IDs via `getTransitionsForJiraIssue` per issue (Jira workflows vary); cache the `(project, transition_name) → id` mapping in the session.

## Capability 4 — Push (create issues from tasks)

Flow:

1. **Read** the target phase from the live plan.
2. **Resolve config** — read changelog header; if missing, prompt for project key + reporter + sprint handling once.
3. **Resolve assignees** — for each task owner in the phase, run the resolution chain above. Show resolved map to user before creating.
4. **Optional epic target date** — for the Epic, ask: "Phase N target completion date? [YYYY-MM-DD or skip]"
5. **Resolve sprint** — compute current month's sprint name; look up on board; create or fall back to label per "Sprint resolution at create time" above.
6. **Show preview** — list of issues to create:
   ```
   Sprint: sprint-2026-05 (id 1234, active on board 67) — all new issues land here

   Phase 5 → Epic: "<PROJECT>: Phase 5 — JIRA connector"
              Owner: Nilay Patel  |  Target: 2026-05-29 (or none)
              Sprint: sprint-2026-05
              Description: 4 sections (achievement, exit criteria, linked spec, context)

     T-5a → Story: "T-5a — JiraConnector class with OAuth/Poll/Checkpoint"
              Assignee: Nilay Patel (cached)  |  3pt  |  Sprint: sprint-2026-05  |  no due date
              Description: 5 sections (what, why, AC: 3 items, impl notes, DoD: 5 items)
     T-5b → Story: ...
     ...
   Total: N issues to create in project <KEY>, all assigned to sprint-2026-05.
   ```
7. **Ask for confirmation.**
8. **Batch-create:**
   - Create the Epic with the Sprint custom field set; capture the returned key (e.g. `<KEY>-100`).
   - Create each Story with `customfield_10014` (Epic Link) = `<KEY>-100` and Sprint set.
   - Capture each story key.
9. **Write back** to the live plan: append `[JIRA: <KEY>-XXX]` next to each task ID.
10. **Append changelog entry** listing all created keys + the epic key + sprint name + any newly-resolved assignee mappings.
11. **Suggest commit message:**
    ```
    docs(plan): link Phase 5 tasks to Jira (<KEY>-100..<KEY>-108)
    ```

### Idempotency on push

Before creating, search by JQL:

```jql
project = <KEY> AND labels = "task-T-5a"
```

If found: skip creation, write back the existing key. Surface in preview as `T-5a → <KEY>-99 (existing, skipped create)`.

## Capability 6 — Pull (sync status from Jira to local plan)

Flow:

1. **Scan** the live plan for `[JIRA: ...]` markers; build the issue-key list.
2. **Batch fetch** via JQL:
   ```jql
   project = <KEY> AND key in (<KEY>-100, <KEY>-101, ...)
   ```
   Use `searchJiraIssuesUsingJql` for batch — much fewer round trips.
3. **Compare** each task's local status vs Jira's:
   - Build a diff list: `T-5a: ⏳ → ✅ (Jira says Done, no commit recorded yet)`
4. **Show preview** of all proposed local changes.
5. **Confirm** → write via Capability 3 protocol.
6. **Optional comment pull:** if user asks ("pull comments from Jira too"), fetch comments per issue and append a `> **Note from Jira (YYYY-MM-DD by user):** ...` block to the task row.

### Bidirectional drift detection

If a task is `✅` locally but `In Progress` in Jira (or vice versa), surface to user:

```
Conflict: T-4d
  Local: ✅ Shipped (commit 44b40f5, 2026-05-14)
  Jira <KEY>-104: In Progress (last updated by Nilay Patel, 2026-05-14)

Likely cause: the task shipped but the Jira ticket wasn't transitioned.

Options:
  (a) Transition Jira <KEY>-104 to Done now (skill calls transitionJiraIssue + adds comment)
  (b) Revert local status to ⏳
  (c) Skip — flag for human to reconcile
```

Default: present options, ask. Don't silently pick.

## Failure modes

| Case | Behavior |
|---|---|
| Jira API rate-limited | Surface to user; pause for the suggested cooldown; retry batch with backoff |
| Issue exists with same label but different summary | Don't overwrite; flag the divergence; ask user to reconcile manually |
| User confirms create but MCP call fails mid-batch | Roll back local-doc writes for the failed-after subset; changelog records partial state with error |
| Local plan has `[JIRA: ?]` placeholder (manually written, no key) | Skip during pull; offer to create the issue during next push |
| Assignee lookup returns no candidates | Leave unassigned + label `needs-assignee` + flag in chat |
| User declines auto-propagate at session start | Capability 3 still updates local; no Jira write happens; logged in changelog as "skipped Jira mirror per session opt-out" |
