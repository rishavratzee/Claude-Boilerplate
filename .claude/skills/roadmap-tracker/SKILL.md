---
name: roadmap-tracker
description: "Repo-aware roadmap and sprint tracker. Discovers the project's planning doc, reports active phase + pipeline, answers narrow questions about phases/tasks, updates task/phase status with commit-style diff preview, generates handoff and sprint-review docs, syncs with Jira (push tasks → issues, pull issue status → tasks), and publishes the plan to Confluence. Use whenever the user asks: 'what's the roadmap', 'what's next', 'status of Phase X', 'mark T-NN done', 'add Phase 12', 'what's blocked', 'show pipeline', 'generate sprint report', 'draft handoff for X', 'create Jira tickets for Phase N', 'publish roadmap to Confluence', or 'sync from Jira'. Each invocation is scoped to the current repo only — the skill auto-discovers the project name and planning doc."
compatibility: "Claude Code, Claude.ai web/desktop, Cowork — anywhere with Read/Write/Bash + (optional) Atlassian MCP for Jira/Confluence integrations"
---

# Roadmap Tracker

Repo-scoped tracker. Each invocation operates on **the current repo's** planning doc only. Auto-discovers the project name and plan path; no per-repo customization required.

## Source-of-truth hierarchy

1. **Repo-local live doc** — `docs/plans/MASTER-PLAN.md` (preferred). Authoritative current state. Updated by humans, by this skill (Capability 3), and by `/planning` + `/ui-planner` (their write-through hook).
2. **Alternate plan locations** (checked in order if #1 missing): `docs/MASTER-PLAN.md`, `MASTER-PLAN.md`, `docs/plans/phase-roadmap.md`, `ROADMAP.md`, `PLAN.md`, any `docs/feature-*.md`.
3. **Skill log** — `docs/plans/.roadmap-tracker-changelog.md` (created on first write). Append-only audit trail of skill-driven changes.
4. **Bootstrap fallback** — if no plan found anywhere, offer to seed one from `references/templates/master-plan-template.md`. **Do not invent state** from architecture docs, READMEs, or commit history.

## Bootstrap protocol — every invocation

**Step 1 — Identify the project.** Infer the name from `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, or the working-directory name as fallback.

**Step 2 — Locate the planning doc.** Walk the source-of-truth hierarchy. Stop at the first match. If multiple candidates exist, prefer the most-recently-modified and surface the conflict.

**Step 3 — Read the changelog.** Open `docs/plans/.roadmap-tracker-changelog.md` if it exists. Apply any pending overrides not yet flushed to the live plan (rare).

**Step 4 — Report briefly.** One short paragraph: which repo, which planning doc, what the active phase is, drift status. Then wait for the next instruction unless the user already specified an action.

**Step 5 — If no plan exists.** Tell the user. Offer to (a) bootstrap a fresh `docs/plans/MASTER-PLAN.md` from the template, or (b) operate on a custom path the user names. **Never invent.**

## Six capabilities

### Capability 1 — Discover & report state

Triggered by: "what's the roadmap", "what's active", "what's next", "show pipeline", "status".

1. Read the live plan.
2. Apply changelog overrides.
3. Report:

```
## <Project name>

**Active:** Phase N — <name>  (<status>)
  Goal: <one-line achievement target>
  Tasks: X of Y done; <next task ID> next
  Recent commits: <hash> <date> <task ID> <by>
  Exit criteria: <bullets, condensed>

**Pipeline:**
  - Phase N+1 — <name>  (~Xw, owner: <who>)
  - Phase N+2 — <name>  (depends on N+1)
  ...

**Drift:** <none / N pending changelog entries unflushed>
```

If multi-track (backend + frontend per phase), show side by side. Narrow if the user asked about a specific phase.

### Capability 2 — Answer narrow questions

Triggered by: "what's T-4e about", "tell me about Phase 8", "what's blocked".

1. Find the section in the live plan. If a deeper spec exists (`docs/specs/`, `docs/handoff/`, `docs/plans/phase-roadmap.md`), read that for detail.
2. Quote goal, scope, tasks, exit criteria succinctly.
3. Apply changelog overrides.
4. Cite `file:line` so the user can navigate.
5. If the source says "TBD" — say so. Don't fabricate.

### Capability 3 — Update phase or task status (commit-style)

Triggered by: "mark T-4e done", "Phase 4 is complete now", "T-4e is in progress", "add Phase 12 — webhooks".

This is a **commit-style write**. Show the diff before writing.

1. Read current state.
2. Draft change as a unified diff (or before/after blocks for structural changes).
3. Show the diff and ask for confirmation.
4. **Only on explicit "yes":**
   - Write the updated planning doc (Edit tool, not Write — preserve unchanged content).
   - Append to `docs/plans/.roadmap-tracker-changelog.md`.
5. Suggest a commit message matching this repo's convention. Sample `git log --oneline -10` to detect format. Don't `git commit` yourself unless asked.

Full protocol + entry shape: `references/status-update-protocol.md`.

### Capability 4 — Publish to Confluence + Jira

Triggered by: "publish roadmap to Confluence", "create Jira tickets for Phase 5", "sync this plan to Jira".

**Pre-flight:** check that `mcp__claude_ai_Atlassian_Rovo__*` tools are available. If not, print the Confluence storage-format and Jira issue-create JSON for manual paste.

**Confluence flow** (full mapping in `references/integrations/confluence-publish.md`):
1. Read the planning doc.
2. Identify or ask for target space + page. Cache the choice in the changelog.
3. Render via `references/templates/confluence-page.md`.
4. Show preview; on confirmation, call `createConfluencePage` or `updateConfluencePage`.
5. Record the page URL in the changelog.

**Jira create flow** (full mapping in `references/integrations/jira-sync.md`):
1. Identify the target phase from the live plan.
2. Identify or ask for the Jira project key. Cache in the changelog.
3. Map: phase → Epic; task → Story (or Task) under the Epic.
4. Show preview list of issues to create. On confirmation, batch-create via `createJiraIssue`.
5. Write back the created keys into the live plan: `T-5a [JIRA: PROJ-123]`.
6. Record keys in the changelog.

### Capability 5 — Generate handoff doc / sprint report

Triggered by: "draft a handoff for <person>", "generate sprint report for last 2 weeks", "what should I send the team this week".

**Handoff doc** (template: `references/templates/handoff-template.md`):
1. Read the live plan + recent commits (`git log --since=...`).
2. Render with: executive context, what each phase achieves, current phase task-by-task, lighter sketches for upcoming phases, owner attribution, open decisions.
3. Save to `docs/handoff/phase-N-handoff.md` (or path the user specifies).

**Sprint report** (template: `references/templates/sprint-report-template.md`):
1. Take a date range (default: last 14 days).
2. Read `git log --since=$RANGE --pretty=format:"%h %ad %an %s"`.
3. Group commits by phase / task ID parsed from the message tail (e.g. `— task T-X.Y`).
4. Render with: shipped tasks + commit hashes, in-flight tasks + status, blockers, next-sprint plan, contributor list with hours estimate from commit timestamps.
5. Save to `docs/handoff/sprint-YYYY-MM-DD.md` or output to chat.

**Attribution caveat (both):** git author may be misleading on shared dev boxes. If a project memory specifies `<person> works on <timezone>` or `physical author = X`, apply it. If new contributors appear, ask via `AskUserQuestion` — don't guess.

### Capability 6 — Sync from Jira

Triggered by: "sync from Jira", "pull task status from PROJ-123", "what's the Jira status of Phase 4".

**Pre-flight:** Atlassian MCP available; live plan must have `[JIRA: PROJ-XYZ]` markers (added by Capability 4 or manually).

1. Scan the live plan for `[JIRA: ...]` markers.
2. Batch-fetch via `searchJiraIssuesUsingJql` (one call, not N).
3. Compare local task status vs Jira:
   - Jira `Done` + local `📋` → propose marking local ✅
   - Jira `In Progress` + local `📋` → propose marking local ⏳
   - Jira `Blocked` / `Impediment` label → flag in local
4. Present diff. On confirmation, write changes via Capability 3.
5. If user asks, pull recent comments and append as `> **Note from Jira (<date> by <user>):** ...` per task.

Full Jira ↔ local status table: `references/integrations/jira-sync.md`.

## Conventions for all output

- **No emojis** outside the dashboard status icons (✅ ⏳ 📋).
- **Cite commit hashes + dates** for shipped work. This is an audit trail.
- **Times in implementer's local timezone** if known (read from a project memory like `<person> works on IST`); UTC otherwise with explicit timezone label.
- **Match the repo's tone** — sample 2-3 existing planning docs first. Formal-spec vs casual-bullet matters.
- **Don't pad.** Empty section = "None — to plan after Phase X exits."
- **Ask before guessing attribution.** Use `AskUserQuestion` when uncertain.

## Integration with /planning and /ui-planner

When `/planning` or `/ui-planner` produces a plan, those skills' final steps now write through to `docs/plans/MASTER-PLAN.md` (the same one this skill reads). Coordination:

- The plan output gets added as a new "Pipeline" phase entry, OR appended to an existing in-progress phase as additional task rows.
- If `MASTER-PLAN.md` doesn't exist, `/planning` (or `/ui-planner`) bootstraps it using `references/templates/master-plan-template.md` from this skill.
- Planning skill writes the full plan as a phase block; this skill then handles status updates over the phase's life.

This means: ask `/planning "X"` once, then everything afterward (status check, Jira sync, sprint report, handoff) flows through the same `MASTER-PLAN.md` via this skill.

## What this skill does NOT do

- **Does not invent plans** from architecture docs / READMEs / commit history. Bootstrap-or-refuse.
- **Does not predict timelines** beyond what the plan declares.
- **Does not edit code, configs, or non-planning docs.** Strictly: `docs/plans/`, `docs/specs/`, `docs/handoff/`, the changelog. Plus (with confirmation) Jira/Confluence.
- **Does not run destructive git ops.** Suggests commit messages; user runs the commit.
- **Does not push to Jira/Confluence without preview + confirmation.** Both are external, multi-user systems.

## Reference files (loaded conditionally)

| File | Loaded when | Purpose |
|---|---|---|
| `references/status-update-protocol.md` | Capability 3 invoked | Commit-style write protocol + changelog entry shape |
| `references/templates/master-plan-template.md` | Bootstrap Step 5 (no plan found) | Skeleton MASTER-PLAN.md to seed from scratch |
| `references/templates/handoff-template.md` | Capability 5 — handoff | Phase handoff doc structure |
| `references/templates/sprint-report-template.md` | Capability 5 — sprint report | Sprint review structure |
| `references/templates/confluence-page.md` | Capability 4 — Confluence | Storage-format template |
| `references/integrations/jira-sync.md` | Capabilities 4 & 6 — Jira | Field mapping rules, JQL helpers, status table |
| `references/integrations/confluence-publish.md` | Capability 4 — Confluence | Page-create vs update logic |

## When the bundle is missing/broken

If `references/` is missing or files are unreadable, this skill can still operate against the live plan — references add depth (templates, mappings) but the bootstrap protocol and Capability 1 work from the live plan alone.

If the user asks "is this skill working", run the bootstrap protocol and report findings out loud.
