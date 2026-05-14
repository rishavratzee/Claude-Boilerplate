# Confluence page template — roadmap publish

Renders `docs/plans/MASTER-PLAN.md` as a Confluence page in storage format. Used by Capability 4 (publish to Confluence).

## Page metadata to set on create/update

- **Title:** `<PROJECT> — Roadmap & Status (last updated YYYY-MM-DD)`
- **Space key:** ask user once per repo, cache in CHANGELOG (e.g. `Default space: ENG`)
- **Parent page:** ask user once per repo, cache in CHANGELOG (e.g. `Default parent: Engineering > Roadmaps`)
- **Labels:** `roadmap`, `<project-slug>`, `auto-generated-by-skill`

## Storage-format body template

```html
<ac:structured-macro ac:name="warning">
  <ac:rich-text-body>
    <p><strong>Auto-generated.</strong> Source: <code>docs/plans/MASTER-PLAN.md</code> in the <PROJECT> repo. Manual edits will be overwritten on next publish. To make a permanent change, edit the source and re-publish via roadmap-tracker.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<p><strong>Last published:</strong> YYYY-MM-DD HH:MM TZ by <user></p>
<p><strong>Source commit:</strong> <code>HASH</code></p>

<h2>Status dashboard</h2>
<!-- Render the dashboard table from MASTER-PLAN.md as a Confluence table -->
<table>
  <thead>
    <tr><th>Phase</th><th>Name</th><th>Status</th><th>Tasks done</th><th>Last commit</th><th>Owner</th></tr>
  </thead>
  <tbody>
    <!-- one <tr> per phase. Status icons map: ✅→<status color=Green>Shipped</status>, ⏳→<status color=Yellow>In progress</status>, 📋→<status color=Grey>Pipeline</status> -->
  </tbody>
</table>

<h2>Roles &amp; contributors</h2>
<!-- table -->

<h2>Done — Phase 1 through N</h2>
<!-- one <h3> per shipped phase, content from MASTER-PLAN -->

<h2>In progress</h2>
<!-- the active phase, full task table -->

<h2>Pipeline</h2>
<!-- one <h3> per pipeline phase -->

<h2>Critical-path summary</h2>
<!-- table -->

<h2>Open decisions</h2>
<!-- table -->

<hr/>
<p><em>Maintained via the <code>roadmap-tracker</code> Claude Code skill. To update, ask Claude in the project repo: "publish roadmap to Confluence."</em></p>
```

## Status icon → Confluence macro mapping

| Local | Confluence storage format |
|---|---|
| ✅ Shipped | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Green</ac:parameter><ac:parameter ac:name="title">Shipped</ac:parameter></ac:structured-macro>` |
| ⏳ In progress | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Yellow</ac:parameter><ac:parameter ac:name="title">In progress</ac:parameter></ac:structured-macro>` |
| 📋 Pipeline | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Grey</ac:parameter><ac:parameter ac:name="title">Pipeline</ac:parameter></ac:structured-macro>` |
| 📋 Backlog | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Grey</ac:parameter><ac:parameter ac:name="title">Backlog</ac:parameter></ac:structured-macro>` |
| 📋 Reserved | `<ac:structured-macro ac:name="status"><ac:parameter ac:name="colour">Blue</ac:parameter><ac:parameter ac:name="title">Reserved</ac:parameter></ac:structured-macro>` |

## Page-create vs update logic

- **First publish for a project:** call `createConfluencePage` with `spaceId`, `parentId`, title, body.
- **Subsequent publishes:** look up the existing page by title in the space (or by stored `pageId` from CHANGELOG); call `updateConfluencePage` with the new `version.number = current + 1`.

Always show the user the page URL after success and append it to CHANGELOG.

## Conflict handling

If `updateConfluencePage` returns 409 (version conflict — someone else edited in Confluence between fetch and update):
1. Re-fetch the current version.
2. Compare: do the manual edits look intentional? (e.g. a comment added, a status manually flipped?)
3. If the manual edits seem important, surface them to the user: "The Confluence page was edited by <user> after our last sync. Their changes: <diff>. Do you want to (a) overwrite, (b) merge by keeping their edits + your new content, (c) abort?"
4. Don't silently overwrite human edits.
