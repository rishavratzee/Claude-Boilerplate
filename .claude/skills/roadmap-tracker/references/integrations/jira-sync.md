# Jira sync — Capabilities 4 (push) and 6 (pull)

## Required tools

- `mcp__claude_ai_Atlassian_Rovo__createJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__getJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__editJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql`
- `mcp__claude_ai_Atlassian_Rovo__getTransitionsForJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__transitionJiraIssue`
- `mcp__claude_ai_Atlassian_Rovo__addCommentToJiraIssue`

If the Atlassian MCP isn't connected, the skill prints the would-be `createJiraIssue` payload as JSON for manual paste.

## Project key resolution

The Jira project key (e.g. `PROJ`) is asked once per repo and cached in the changelog as a header note:

```markdown
## YYYY-MM-DD — Jira configuration set

- **Jira project:** <KEY>
- **Default issue type for tasks:** Story
- **Default epic strategy:** create new "<PROJECT>: Phase N — <name>"
- **Reporter:** <name>
- **Set by:** <user>
```

Future invocations read this header from the changelog before prompting.

## Mapping: phase → Epic; task → Story

### Phase → Epic
- **Issue type:** `Epic`
- **Summary:** `<PROJECT>: Phase N — <name>` (e.g. `myservice: Phase 4 — Org-admin policy layer`)
- **Description:** "Achievement target" paragraph from the plan, plus a footer linking back to `docs/plans/MASTER-PLAN.md` and `docs/plans/phase-roadmap.md` (if present).
- **Labels:** `roadmap`, `phase-N`, `<project-slug>`
- **Custom field — Epic Name** (where required): `Phase N — <name>`

### Task → Story (or Task)
- **Issue type:** `Story` by default; `Task` if the user prefers (configurable per-project).
- **Summary:** `T-N.X — <one-line title>` (e.g. `T-4e — Routes for /api/orgs/{id} + connector-policies CRUD`)
- **Description:** Full task body from `docs/handoff/<phase-handoff>.md` if available, else from the plan row. Format as ADF (Atlassian Document Format) — wrap multi-line content in code blocks where literal commands.
- **Epic Link:** the Phase epic created above.
- **Labels:** `roadmap`, `task-T-N-X`, the area tag from the commit convention (e.g. `auth`, `db`, `web`).
- **Story points:** estimate from the size in the handoff (1pt ≈ 2h, 2pt ≈ 4h, 3pt ≈ 6h, 5pt ≈ 1 day, 8pt ≈ 2 days).
- **Assignee:** the owner from the plan's "owner" column or "implementer" from the changelog; ask if unclear.

## Local status icon ↔ Jira status mapping

| Local | Jira status | Transition action |
|---|---|---|
| 📋 Pipeline | `To Do` / `Backlog` | (initial state on create) |
| ⏳ In progress | `In Progress` | call `transitionJiraIssue` with the `Start progress` transition |
| ✅ Shipped | `Done` | call `transitionJiraIssue` with `Done` transition |
| (Blocked) | `Blocked` (if project has it) or label `impediment` | call `editJiraIssue` to add label |

Discover transition IDs via `getTransitionsForJiraIssue` per issue (Jira workflows vary); cache the `(project, transition_name) → id` mapping in memory for the session.

## Capability 4 — Push (create issues from tasks)

Flow:

1. **Read** the target phase from the live plan.
2. **Show preview** — list of issues to create:
   ```
   Phase 5 → Epic: "myservice: Phase 5 — JIRA connector"
     T-5a → Story: "T-5a — JiraConnector class with OAuth/Poll/Checkpoint"  (3pt, owner: <name>)
     T-5b → Story: "T-5b — JiraSelectionConfig"  (1pt, owner: <name>)
     ...
   Total: N issues to create in project <KEY>.
   ```
3. **Ask for confirmation.**
4. **Batch-create:**
   - First create the Epic; capture the returned key (e.g. `<KEY>-100`).
   - Then create each Story with `customfield_10014` (Epic Link) = `<KEY>-100`.
   - Capture each story key.
5. **Write back** to the live plan: append `[JIRA: <KEY>-XXX]` next to each task ID. Use Edit tool with the task-row pattern as the unique anchor.
6. **Append changelog entry** listing all created keys + the epic key.
7. **Suggest commit message:**
   ```
   docs(plan): link Phase 5 tasks to Jira (<KEY>-100..<KEY>-108)
   ```

### Idempotency on push

Before creating, search for existing issues by JQL:

```jql
project = <KEY> AND labels = "task-T-5a"
```

If found: skip creation, write back the existing key (someone created the ticket manually). Surface this in the preview as `T-5a → <KEY>-99 (existing, skipped create)`.

## Capability 6 — Pull (sync status from Jira to local plan)

Flow:

1. **Scan** the live plan for `[JIRA: ...]` markers; build the issue-key list.
2. **Batch fetch** via JQL:
   ```jql
   project = <KEY> AND key in (<KEY>-100, <KEY>-101, ...)
   ```
   Use `searchJiraIssuesUsingJql` for batch — much fewer round trips than per-key `getJiraIssue`.
3. **Compare** each task's local status vs Jira's:
   - Build a diff list: `T-5a: ⏳ → ✅ (Jira says Done, commit pending)`
4. **Show preview** of all proposed local changes.
5. **Confirm** → write via Capability 3 protocol (single combined diff, single changelog entry).
6. **Optional comment pull:** if user asks ("pull comments from Jira too"), fetch comments per issue and append a `> **Note from Jira (YYYY-MM-DD by user):** ...` block to the task row.

### Bidirectional drift detection

If a task is `✅` locally but `In Progress` in Jira, that's a real conflict:

```
Conflict: T-4d
  Local: ✅ Shipped (commit 44b40f5, 2026-05-14)
  Jira <KEY>-104: In Progress (last updated by <user>, 2026-05-14)

The local plan says it's done but Jira says it's still in progress. Likely cause: the task shipped but the Jira ticket wasn't transitioned.

Options:
  (a) Transition Jira <KEY>-104 to Done now (skill calls transitionJiraIssue)
  (b) Revert local status to ⏳
  (c) Skip — flag for human to reconcile
```

Default: present options + ask. Don't silently pick one.

## Comment-back on shipped tasks (optional)

When Capability 3 marks a task ✅ and the task has a Jira key:

1. Fetch the issue.
2. Add a comment via `addCommentToJiraIssue`:
   ```
   Task T-4d completed in commit 44b40f5 on 2026-05-14.
   See docs/plans/MASTER-PLAN.md for context.
   ```
3. Optionally transition the issue to `Done` (ask the user once per session whether to auto-transition).

## Failure modes

| Case | Behavior |
|---|---|
| Jira API rate-limited | Surface to user; pause for the suggested cooldown; retry batch with backoff |
| Issue exists with same label but different summary | Don't overwrite; flag the divergence; ask user to reconcile manually |
| User confirms create but MCP call fails mid-batch | Roll back local-doc writes for the failed-after subset; changelog records partial state with error |
| Local plan has `[JIRA: ?]` placeholder (someone wrote it manually but didn't fill the key) | Skip during pull; offer to create the issue during next push |
