# Confluence page template — concise single-page roadmap

Renders the project's roadmap as a **single Confluence page** scoped to executive consumption. Updated in place on every publish (page version increments). Engineering-level detail stays in `docs/plans/MASTER-PLAN.md` in the repo; this page links to it for engineers who need depth.

**Goal:** scannable in 30 seconds.

## Page metadata

- **Title:** `<PROJECT> — Roadmap`  (no date in title — updated in place; date moves to footer)
- **Space key:** asked once per repo, cached in changelog
- **Parent page:** asked once per repo, cached in changelog
- **Labels:** `roadmap`, `<project-slug>`, `auto-generated-by-skill`

## Storage-format body

```html
<ac:structured-macro ac:name="info">
  <ac:rich-text-body>
    <p>Auto-generated single-page roadmap for <strong><PROJECT></strong>. Source: <code>docs/plans/MASTER-PLAN.md</code> in the repo. Manual edits will be overwritten on next publish — open a PR against the repo source to make permanent changes.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<h2>What we're building</h2>
<p><EXECUTIVE_SUMMARY one paragraph: the project goal in user-facing terms, plus the current focus. Pulled from MASTER-PLAN's purpose line + the active phase's achievement target. Aim for 2-3 sentences.></p>

<h2>Phase overview</h2>
<table>
  <thead>
    <tr><th>Phase</th><th>Status</th><th>Owner</th><th>Outcome</th></tr>
  </thead>
  <tbody>
    <!-- one <tr> per phase from MASTER-PLAN's status dashboard.
         Status uses Confluence status macro (mapping below).
         Outcome is one line — the phase's achievement target compressed to ≤ 100 chars. -->
  </tbody>
</table>

<h2>Active roadmap</h2>
<!-- For each phase with status ⏳ In progress: -->
<h3><PHASE_NAME> — <STATUS_MACRO></h3>
<p><strong>Goal:</strong> <one-line user-facing outcome></p>
<p><strong>Progress:</strong> X of Y tasks done</p>
<p><strong>Started:</strong> <YYYY-MM-DD></p>
<p><strong>ETA:</strong> <YYYY-MM-DD if known, else "no firm date"></p>
<!-- If multiple phases are in progress (rare), repeat. If none, render: -->
<!-- <p><em>No phases in active development. See planned roadmap below.</em></p> -->

<h2>Planned roadmap</h2>

<h3>Pipeline (next up)</h3>
<ul>
  <!-- one <li> per phase with status 📋 Pipeline:
       <strong>Phase N — name</strong> (~Xw, owner: <name>): <one-line goal>
       Limit to next 5; if more, add "and N more — see MASTER-PLAN.md for full list" -->
</ul>

<h3>Backlog (further out)</h3>
<ul>
  <!-- one <li> per phase with status 📋 Backlog or 📋 Reserved:
       <strong>Phase N — name</strong>: <one-line goal>
       Limit to next 5 by name only -->
</ul>

<h2>Recently shipped</h2>
<p>Phases 1 through <LAST_SHIPPED_PHASE> are complete. Most recent: <LAST_SHIPPED_PHASE_NAME> on <DATE>.</p>
<p><em>Full history: <code>docs/plans/MASTER-PLAN.md</code> "Done" section in the repo.</em></p>

<hr/>
<p><small>
  Last published <YYYY-MM-DD HH:MM TZ> from commit <code><HASH></code> by <USER>.<br/>
  Engineering-level detail (per-task tables, commit hashes, exit criteria, decisions): see <code>docs/plans/MASTER-PLAN.md</code> in the repo.<br/>
  Maintained via the <code>roadmap-tracker</code> Claude Code skill. To refresh, ask Claude in the project repo: "publish roadmap to Confluence."
</small></p>
```

## What this template does NOT include (vs the verbose alternative)

These are intentionally excluded to keep the page scannable:

- **Per-task tables** — task-level detail is engineering concern; lives in MASTER-PLAN.md
- **Commit hash audit trail** — same; engineers look in repo
- **Roles & contributors deep dive** — owner column in the phase table is enough
- **Open decisions table** — engineering concern; lives in spec docs
- **Test posture / coverage / lint state** — out of place for an exec page
- **Detailed exit criteria** — too much for a 30-second scan; the phase Outcome line carries the gist

If a stakeholder asks for any of the above, point them at the repo, not the Confluence page.

## Status icon → Confluence macro mapping

| Local | Confluence storage format |
|---|---|
| ✅ Shipped | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Green</ac:parameter><ac:parameter ac:name="title">Shipped</ac:parameter></ac:structured-macro>` |
| ⏳ In progress | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Yellow</ac:parameter><ac:parameter ac:name="title">In progress</ac:parameter></ac:structured-macro>` |
| 📋 Pipeline | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Blue</ac:parameter><ac:parameter ac:name="title">Pipeline</ac:parameter></ac:structured-macro>` |
| 📋 Backlog | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Grey</ac:parameter><ac:parameter ac:name="title">Backlog</ac:parameter></ac:structured-macro>` |
| 📋 Reserved | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Grey</ac:parameter><ac:parameter ac:name="title">Reserved</ac:parameter></ac:structured-macro>` |

## When the plan has no in-progress phases

Render the "Active roadmap" section as:

```html
<p><em>No phases in active development. <strong>Phase N — &lt;name&gt;</strong> is the next planned start (see Pipeline below).</em></p>
```

This handles the "between phases" gap or a project that's only had planning so far (no work started).

## When the plan has only planning, no work yet

If MASTER-PLAN.md exists but every phase is 📋 (no ⏳ or ✅), the page renders:

- "What we're building" — pulls from MASTER-PLAN's purpose
- "Phase overview" — full pipeline visible
- "Active roadmap" — "No phases in active development. Planning complete; next start: Phase 1."
- "Planned roadmap" — Pipeline + Backlog as normal
- "Recently shipped" — "Nothing shipped yet — project is in planning."

This is the "planned roadmap, only planning was done" mode.
