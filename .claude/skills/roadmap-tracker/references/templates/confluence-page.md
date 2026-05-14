# Confluence templates — three-page roadmap structure

Per-project roadmap published as a parent page with two children. Updated in place on every publish (page versions increment).

```
<Confluence space>
└── <PROJECT> — Roadmap        (parent: overview + all-phase table + links to children)
    ├── <PROJECT> — Current    (only ⏳ In progress phases: goal, progress, ETA + recent ships)
    └── <PROJECT> — Future     (📋 Pipeline + Backlog phases: goal, size, dependencies)
```

**Why three pages:** lets stakeholders bookmark "Current" and check it weekly without scrolling past planned-but-not-started work; lets execs scan the parent for the all-up phase table; lets PMs/leadership look at "Future" when scoping the next quarter.

**Single-page-per-project alternative** (if you want this, change config flag `confluence_layout: single` in changelog): everything renders into the parent only, no children created. Default is `confluence_layout: three-page` per scrum-master recommendation.

## Page metadata

All three pages share:
- **Space key:** asked once per repo, cached in changelog
- **Labels:** `roadmap`, `<project-slug>`, `auto-generated-by-skill`
- **Updated in place** on every publish (no rotating titles, no date in title — date moves to footer)

Parent page additional:
- **Title:** `<PROJECT> — Roadmap`
- **Parent in tree:** asked once per repo (space home or a dedicated "Roadmap" hub page)

Children additional:
- **Titles:** `<PROJECT> — Current` and `<PROJECT> — Future`
- **Parent in tree:** the parent roadmap page (auto)

---

## Parent page body — `<PROJECT> — Roadmap`

```html
<ac:structured-macro ac:name="info">
  <ac:rich-text-body>
    <p>Auto-generated roadmap for <strong><PROJECT></strong>. Source: <code>docs/plans/MASTER-PLAN.md</code> in the repo. Manual edits will be overwritten on next publish.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<h2>What we're building</h2>
<p><EXECUTIVE_SUMMARY 2-3 sentences: project goal in user-facing terms + current focus. From MASTER-PLAN purpose + active phase achievement.></p>

<h2>Quick navigation</h2>
<ul>
  <li><strong><ac:link><ri:page ri:content-title="<PROJECT> — Current"/></ac:link></strong> — what's in active development right now</li>
  <li><strong><ac:link><ri:page ri:content-title="<PROJECT> — Future"/></ac:link></strong> — what's planned but not started</li>
</ul>

<h2>All phases — status overview</h2>
<table>
  <thead>
    <tr><th>Phase</th><th>Status</th><th>Owner</th><th>Outcome</th></tr>
  </thead>
  <tbody>
    <!-- one <tr> per phase from MASTER-PLAN dashboard.
         Status: Confluence status macro (mapping below).
         Outcome: ≤100 chars from achievement target. -->
  </tbody>
</table>

<h2>Critical-path summary</h2>
<p><CRITICAL_PATH_LINE — pulled from MASTER-PLAN's "Critical path" line. e.g. "Phases 4 → 9: ~16 calendar weeks at one BE + one FE engineer working sequentially."></p>

<hr/>
<p><small>
  Last published <YYYY-MM-DD HH:MM TZ> from commit <code><HASH></code> by <USER>.<br/>
  Engineering detail (per-task tables, commit hashes, exit criteria, decisions): <code>docs/plans/MASTER-PLAN.md</code> in the repo.
</small></p>
```

---

## Current page body — `<PROJECT> — Current`

```html
<ac:structured-macro ac:name="info">
  <ac:rich-text-body>
    <p>What's in <strong>active development</strong> for <PROJECT>. For planned but not-yet-started work, see <ac:link><ri:page ri:content-title="<PROJECT> — Future"/></ac:link>. For the all-phase overview, see <ac:link><ri:page ri:content-title="<PROJECT> — Roadmap"/></ac:link>.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<h2>Active phases</h2>
<!-- For each phase with status ⏳ In progress: -->
<h3><PHASE_NAME></h3>
<p><STATUS_MACRO_YELLOW></p>
<p><strong>Goal:</strong> <one-line user-facing outcome></p>
<p><strong>Progress:</strong> X of Y tasks done</p>
<p><strong>Started:</strong> <YYYY-MM-DD></p>
<p><strong>ETA:</strong> <YYYY-MM-DD if known, else "no firm date"></p>
<p><strong>Owner:</strong> <name></p>
<p><strong>Exit criteria (condensed):</strong></p>
<ul>
  <!-- 3-5 bullets from phase exit criteria, condensed to ≤ 80 chars each -->
</ul>
<p><strong>Spec:</strong> <code>docs/specs/<spec>.md</code> in the repo</p>

<!-- Repeat per active phase. If none: -->
<!-- <p><em>No phases in active development.
       <strong><PHASE N — name></strong> is next planned start
       (see <ac:link><ri:page ri:content-title="<PROJECT> — Future"/></ac:link>).</em></p> -->

<h2>Recently shipped</h2>
<p>Most recently completed: <strong><LAST_SHIPPED_PHASE_NAME></strong> on <DATE>.</p>
<p>All phases through <LAST_SHIPPED_PHASE> are complete (<COUNT> total). Full list with commit hashes: <code>docs/plans/MASTER-PLAN.md</code> "Done" section.</p>

<hr/>
<p><small>Last published <YYYY-MM-DD HH:MM TZ> from commit <code><HASH></code>. Updated whenever roadmap-tracker writes status changes.</small></p>
```

---

## Future page body — `<PROJECT> — Future`

```html
<ac:structured-macro ac:name="info">
  <ac:rich-text-body>
    <p>What's <strong>planned but not started</strong> for <PROJECT>. For active work, see <ac:link><ri:page ri:content-title="<PROJECT> — Current"/></ac:link>. For the all-phase overview, see <ac:link><ri:page ri:content-title="<PROJECT> — Roadmap"/></ac:link>.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<h2>Pipeline (next up)</h2>
<p><em>Phases planned for the immediate next chunks of work, in order.</em></p>
<!-- For each phase with status 📋 Pipeline: -->
<h3><PHASE_NAME></h3>
<p><STATUS_MACRO_BLUE></p>
<p><strong>Goal:</strong> <one-line user-facing outcome></p>
<p><strong>Size:</strong> ~Xw  |  <strong>Owner:</strong> <name></p>
<p><strong>Depends on:</strong> <prior phase or "ready to start when capacity available"></p>
<p><strong>Why now:</strong> <one-line reasoning from phase-roadmap.md></p>

<!-- If no Pipeline phases: -->
<!-- <p><em>Nothing in the immediate Pipeline. See Backlog below.</em></p> -->

<h2>Backlog (further out)</h2>
<p><em>Phases on the radar but not committed to a sequence yet.</em></p>
<!-- For each phase with status 📋 Backlog: -->
<h3><PHASE_NAME></h3>
<p><STATUS_MACRO_GREY></p>
<p><strong>Goal:</strong> <one-line user-facing outcome></p>
<p><strong>Size estimate:</strong> ~Xw (rough)  |  <strong>Owner:</strong> <TBD or name></p>

<h2>Reserved (long-term ideas)</h2>
<p><em>Architectural reservations — features the data model or design accommodates but no plan to build yet.</em></p>
<ul>
  <!-- bullets per Reserved phase, one-line each -->
</ul>

<hr/>
<p><small>Last published <YYYY-MM-DD HH:MM TZ> from commit <code><HASH></code>. Reordering happens when roadmap-tracker writes phase scope changes.</small></p>
```

---

## Status icon → Confluence macro mapping

| Local | Storage format |
|---|---|
| ✅ Shipped | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Green</ac:parameter><ac:parameter ac:name="title">Shipped</ac:parameter></ac:structured-macro>` |
| ⏳ In progress | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Yellow</ac:parameter><ac:parameter ac:name="title">In progress</ac:parameter></ac:structured-macro>` |
| 📋 Pipeline | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Blue</ac:parameter><ac:parameter ac:name="title">Pipeline</ac:parameter></ac:structured-macro>` |
| 📋 Backlog | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Grey</ac:parameter><ac:parameter ac:name="title">Backlog</ac:parameter></ac:structured-macro>` |
| 📋 Reserved | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Grey</ac:parameter><ac:parameter ac:name="title">Reserved</ac:parameter></ac:structured-macro>` |

## Edge cases

| Case | Behavior |
|---|---|
| No phases in any status | Render parent with "Project is in planning — no phases defined yet"; skip both children create until at least one phase exists |
| All phases shipped | Current page renders as "All work complete. Recently shipped: <last>"; Future renders as "No planned phases. Add via /planning to populate." |
| One project, multiple in-progress phases | Current page lists both; usually a sign of unfocused work, but skill doesn't judge |
| Renamed project (package.json change) | Skill detects and asks: "Project renamed from <old> to <new>. Rename the existing Confluence pages, or leave old pages as archive and create new tree?" Default: rename in place via `updateConfluencePage` (preserves URL + history). |
