# Confluence publish — Capability 4

## Required tools

- `mcp__claude_ai_Atlassian_Rovo__createConfluencePage`
- `mcp__claude_ai_Atlassian_Rovo__updateConfluencePage`
- `mcp__claude_ai_Atlassian_Rovo__getConfluencePage`
- `mcp__claude_ai_Atlassian_Rovo__getConfluenceSpaces`
- `mcp__claude_ai_Atlassian_Rovo__getPagesInConfluenceSpace`
- `mcp__claude_ai_Atlassian_Rovo__searchConfluenceUsingCql`

If Atlassian MCP isn't connected, the skill prints the storage-format body for manual paste into Confluence's editor in source-mode.

## Configuration (asked once per repo, cached in CHANGELOG)

```markdown
## YYYY-MM-DD — Confluence configuration set

- **Cloud:** <subdomain>.atlassian.net
- **Space key:** <KEY>
- **Layout:** three-page  (or "single" — see "Three-page model" below)
- **Upper parent:** <breadcrumb>  (id: <pageId>)
                    where the project's roadmap folder lives — usually space home or
                    a shared "Roadmap" hub page across all projects
- **Page IDs:** set after first publish
  - parent: <PROJECT> — Roadmap        →  <id>
  - child:  <PROJECT> — Current        →  <id>
  - child:  <PROJECT> — Future         →  <id>
- **Set by:** <user>
```

Future invocations read from CHANGELOG before prompting.

## Three-page model (default)

**One parent + two children per project, updated in place.** Default `confluence_layout: three-page` in the changelog config. Layout:

```
<Confluence space>
└── <PROJECT> — Roadmap        (parent: overview, all-phase table, links to children)
    ├── <PROJECT> — Current    (only ⏳ phases: progress detail, recent ships)
    └── <PROJECT> — Future     (📋 phases: Pipeline + Backlog + Reserved)
```

Why three pages: stakeholders bookmark "Current" for weekly status; execs scan parent for phase table; PMs use "Future" for next-quarter scoping.

Override: set `confluence_layout: single` in the changelog config block to render everything into the parent only (no children created or updated). Falls back to the prior single-page format from `confluence-page.md` storage block "Parent page body" used as the whole-page body.

## Page-create vs update logic (three-page mode)

### First publish for a project
1. Resolve the **upper parent** (where the project's roadmap folder lives) via `searchConfluenceUsingCql` if user gave a title, else use the `parentId` cached in changelog. Common choices: space home, or a dedicated org-level "Roadmap" hub page.
2. Render three bodies via `references/templates/confluence-page.md` (parent / Current / Future sections).
3. **Create parent first** (children need its pageId):
   ```json
   {
     "spaceId": "<spaceId>",
     "title": "<PROJECT> — Roadmap",
     "parentId": "<upper-parent-id>",
     "body": {"storage": {"value": "<parent body>", "representation": "storage"}}
   }
   ```
   Capture `parentRoadmapPageId`.
4. **Create Current** under the parent:
   ```json
   {
     "spaceId": "<spaceId>",
     "title": "<PROJECT> — Current",
     "parentId": "<parentRoadmapPageId>",
     "body": {"storage": {"value": "<current body>", "representation": "storage"}}
   }
   ```
   Capture `currentPageId`.
5. **Create Future** under the parent (same shape, title `<PROJECT> — Future`). Capture `futurePageId`.
6. Append to CHANGELOG:
   ```markdown
   ## YYYY-MM-DD — Confluence published (initial three-page)

   - **Layout:** three-page
   - **Space:** <KEY>  |  **Cloud:** <subdomain>.atlassian.net
   - **Upper parent:** <upper-parent-title> (id <upper-parent-id>)
   - **Roadmap parent:** <PROJECT> — Roadmap (id <parentRoadmapPageId>)
     - URL: https://<domain>.atlassian.net/wiki/spaces/<KEY>/pages/<parentRoadmapPageId>
   - **Current child:** <PROJECT> — Current (id <currentPageId>)
   - **Future child:** <PROJECT> — Future (id <futurePageId>)
   - **Source commit:** <hash>
   ```
7. Show all three URLs to user, parent first.

### Subsequent publishes
1. Read cached `parentRoadmapPageId`, `currentPageId`, `futurePageId` from CHANGELOG.
2. For each, fetch current `version.number` via `getConfluencePage`.
3. Re-render all three bodies (titles stable, date in footer).
4. `updateConfluencePage` for each, in order: parent → Current → Future. Each gets `version.number = current + 1`.
5. Append to CHANGELOG:
   ```markdown
   ## YYYY-MM-DD — Confluence published (update three-page)

   - **Pages updated:** parent (vN → vN+1), Current (vM → vM+1), Future (vK → vK+1)
   - **Source commit:** <hash>
   - **Trigger:** <user prompt>
   ```

### Optimization: skip unchanged pages
On subsequent publishes, compute the storage-format hash of each body before update. If a body hasn't changed since last publish (hash cached in CHANGELOG), skip the update for that page. Reduces noise in Confluence page-history when only one section moved.

E.g., if T-4e moves 📋 → ⏳: Current page changes (now shows T-4e in active list); Future page might lose T-4e from Pipeline; parent table updates the phase status. Three updates. If only metadata changed, fewer.

## Conflict handling on update

If `updateConfluencePage` returns 409 (version conflict — someone edited in Confluence after our last fetch):

1. Fetch current page content.
2. Compare against the storage-format we last wrote (cached in CHANGELOG as a content hash, not the full body).
3. Surface to user:
   ```
   The Confluence page was edited in the wiki since our last publish (version N → N+M).
   Recent editor: <user> at <timestamp>.
   Their changes (text diff against last-known): <summary>

   Options:
     (a) Overwrite — push our new render, discard their edits
     (b) Pull-then-push — read their edits, regenerate from MASTER-PLAN.md merging in their text-only additions, push
     (c) Abort — leave both as-is; you reconcile manually
   ```
4. Default: present options + ask. **Never silently overwrite human edits in shared-system output.**

## Section-level updates (optional, advanced)

For surgical updates (e.g. "publish only the dashboard, not the full plan"), use Confluence's section-targeting via `<ac:structured-macro ac:name="section">` markers. The skill renders the body with stable `id="dashboard"`, `id="pipeline"`, etc. on each H2, then uses XPath replacement on update.

This is a Phase-2 enhancement — not in the initial implementation. For now, every publish replaces the full body.

## Inline comments (read-only)

If the user asks "what comments are on the Confluence roadmap page?", call `getConfluencePageInlineComments(pageId)` and `getConfluencePageFooterComments(pageId)`. Render as a list with author, date, comment text, and the section it's anchored to. Don't create comments programmatically — that's a stakeholder-communication action that should be human-driven.

## Page deletion

The skill never deletes pages. If a project is archived and the user wants the roadmap page gone, they delete it manually in Confluence — this is an irreversible shared-system action.

## Failure modes

| Case | Behavior |
|---|---|
| Space ID resolves to multiple matches | Show options; ask user to pick |
| Parent page not found | Offer (a) create at space root, (b) ask user for a different parent |
| Body too large for Confluence (>500KB) | Compress: drop "Done" sections older than current-1 phase; link to git history instead |
| User on free Confluence tier (no labels API) | Skip label-set step; warn user |
| Atlassian MCP disconnected mid-flow | Save the rendered body to `/tmp/confluence-body-YYYY-MM-DD.html`; tell user the path for manual paste |
