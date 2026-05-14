# Status update protocol — Capability 3

Commit-style writes to the live planning doc follow this strict protocol. The user reviews a diff before anything is written.

## Protocol steps

1. **Read current state** of the live plan (`docs/plans/MASTER-PLAN.md` or whatever path the bootstrap protocol resolved).
2. **Draft the change** as a unified diff or, for structural changes, before/after blocks.
3. **Show the user the diff and ask for confirmation.** Use plain text — quote literal file content; don't invent fancy diff syntax.
4. **Only on explicit "yes" / "go ahead" / equivalent**, write:
   - The updated plan (use Edit tool, not Write — preserve unchanged content).
   - An append to `docs/plans/.roadmap-tracker-changelog.md` with the entry shape below. Create that file if it doesn't yet exist.
5. **Suggest a commit message** matching this repo's convention (see "Detect commit convention" below). Don't `git commit` yourself unless the user asks.
6. **Never** amend an existing changelog entry. Only append.

## Changelog entry shape

```markdown
## YYYY-MM-DD — <Change type>

- **Task / Phase:** <T-X.Y or Phase N>
- **Change:** <one-line description: e.g. "📋 → ⏳ in progress" or "✅ done, commit abc1234">
- **Reason:** <user-supplied or "not given">
- **Reporter:** <who told the skill to update — usually the user>
- **Implementer:** <who actually did the work, if different — read from project memory if available>
```

Date: today's date in ISO format (YYYY-MM-DD), in the user's local timezone.

## Change types (use one as the section header)

| Type | When to use |
|---|---|
| `Task status` | A task icon flipped (📋 → ⏳, ⏳ → ✅, ✅ → 📋 rollback) |
| `Phase status` | A phase moved between Pipeline / In progress / Shipped |
| `Phase added` | New phase appended to the plan (often via /planning or /ui-planner) |
| `Phase scope edit` | Goal / achievement / exit criteria changed |
| `Decision change` | An entry in the open-decisions table changed |
| `Owner change` | Roles & contributors table updated |
| `Other` | Anything else, with a clear description |

## Detect commit convention

Before suggesting a commit message, sample the repo's recent history:

```bash
git log --oneline -10
```

Common patterns:
- **Conventional commits**: `feat(scope): subject — task T-X.Y` or just `feat(scope): subject`
- **Ticket-prefixed**: `[PROJ-123] subject`
- **Plain imperative**: `Add foo to bar`
- **Type-only**: `fix: subject`

Match the pattern. For roadmap-tracker writes (plan-only changes, no code), prefer:

- `docs(plan): <one-line> — <task ID or "bulk update">`

Examples:
- `docs(plan): T-4e marked in-progress`
- `docs(plan): bulk status sync from Jira — 6 tasks updated`
- `docs(plan): Phase 12 added — webhook event connectors`

If the repo uses a totally different convention, mirror it. Body should explain *why* (incident, decision, feedback received) when non-obvious. Trailing `Co-Authored-By:` line is appropriate when this skill drafted the diff.

## Resolving stale status (if live plan and changelog disagree)

The changelog is the skill's audit trail. The live plan is canonical. They should always agree because the skill writes both atomically. If they don't:

- **For phase status** (Pipeline ↔ In progress ↔ Shipped): the most recent changelog entry wins on the assumption the user confirmed it.
- **For task icon state**: live plan wins, *unless* a later changelog entry explicitly flipped it without a corresponding plan write (skill aborted mid-write).
- **For text content** (goal, scope, descriptions): live plan always wins; changelog only records that a change happened, not the verbatim new content.

Reporting state: silently reconcile — don't show the conflict mechanics unless the user asks. If the conflict is unresolvable (e.g. changelog says T-4e ✅ but plan says T-4e ⏳ with no reason), surface it: "T-4e shows ⏳ in the live plan but a 2026-05-15 changelog entry marked it ✅. Which is correct?"

## Failure modes

| Case | Behavior |
|---|---|
| User says "no" to the diff | Discard. Don't write anything. Don't append to changelog. |
| User says "yes" but Edit fails | Revert: don't append to changelog either. Surface the error. |
| User edits the live plan directly between Read and Edit | Detected if the Edit tool errors on stale match. Re-read, re-diff, ask again. |
| Multiple tasks updated in one go | Show one combined diff, confirm once, write all, single changelog entry with `Change:` listing all |
| Phase added with no task list yet | Write the phase header + "tasks: TBD when phase starts"; flag as a follow-up in chat |
| `docs/plans/MASTER-PLAN.md` doesn't exist | Halt — bootstrap-or-refuse per SKILL.md Step 5. Don't write to a non-existent file path. |
