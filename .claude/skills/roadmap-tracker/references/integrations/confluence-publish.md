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
- **Parent page:** <breadcrumb>  (id: <pageId>)
- **Page title:** "<PROJECT> — Roadmap"  (no date in title — date is in footer; page is updated in place)
- **Page ID:** <set after first publish>
- **Set by:** <user>
```

Future invocations read from CHANGELOG before prompting.

## Single-page model

**One page per project, updated in place.** Never multiple pages per phase or per concern. Reasons:

- Stakeholders bookmark the page; rotating URLs breaks their muscle memory
- Confluence page history shows the change record automatically (no need for separate per-publish pages)
- Single page = single search result when execs look up the project

If a stakeholder needs a frozen snapshot for a specific moment (board meeting, quarterly review), they can use Confluence's native "Page History" → "Restore this version" — no special skill behavior needed.

## Page-create vs update logic

### First publish for a project
1. Resolve the parent page ID (search via `searchConfluenceUsingCql` if user gave a parent title).
2. Render the body using `references/templates/confluence-page.md` (the concise single-page format).
3. Call `createConfluencePage`:
   ```json
   {
     "spaceId": "...",
     "title": "<PROJECT> — Roadmap",
     "parentId": "...",
     "body": {"storage": {"value": "<rendered storage format>", "representation": "storage"}}
   }
   ```
4. Capture `pageId` from response. Store in CHANGELOG:
   ```markdown
   ## YYYY-MM-DD — Confluence published (initial)

   - **Page:** <PROJECT> — Roadmap
   - **URL:** https://<domain>.atlassian.net/wiki/spaces/<KEY>/pages/<pageId>
   - **Page ID:** <pageId>
   - **Source commit:** <hash>
   ```
5. Show URL to user.

### Subsequent publishes
1. Read the cached `pageId` from CHANGELOG.
2. `getConfluencePage(pageId)` to get current `version.number`.
3. Re-render body (title stays the same — date moves to footer).
4. `updateConfluencePage`:
   ```json
   {
     "pageId": "...",
     "title": "<PROJECT> — Roadmap",
     "body": {"storage": {"value": "...", "representation": "storage"}},
     "version": {"number": <current + 1>}
   }
   ```
5. Append to CHANGELOG:
   ```markdown
   ## YYYY-MM-DD — Confluence published (update)

   - **Page:** <title>
   - **Version:** N → N+1
   - **Source commit:** <hash>
   - **Trigger:** <user prompt that caused publish, e.g. "publish roadmap to Confluence">
   ```

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
