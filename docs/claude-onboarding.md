# Claude SDLC Onboarding — 90 minutes to productive

You (or a new teammate) just cloned a repo with this boilerplate installed. This guide gets you to "shipping real work with a team of Claude specialists" in 90 minutes.

## Prereqs
- Claude Code installed. If not: [Claude Code docs](https://docs.claude.com/en/docs/claude-code/overview)
- You're on the repo's default branch and dependencies are installed (`pnpm install` / `pip install -r requirements.txt` / `go mod download` / etc).

## Minute 0–15 — Orientation

1. Open the repo in Claude Code (`cmd+esc` in VS Code, or `claude` in the terminal from the repo root).
2. Read these in order:
   - `CLAUDE.md` — the project-level context. Everything below the `<!-- BEGIN CLAUDE-SDLC-BOILERPLATE -->` marker is auto-generated; everything outside is yours to fill in. Fill in the `TODO` items you know.
   - `CLAUDE-activeContext.md` — your living notebook for what's in progress. Update it at the start of new work threads.
   - `CLAUDE-patterns.md`, `CLAUDE-decisions.md`, `CLAUDE-troubleshooting.md` — fill in as the project accumulates reusable patterns, ADR-lite decisions, and weird-bug fixes. Claude reads these on session start.
3. Skim `.claude/skills/` and `.claude/agents/` to see what's installed. Each has a 1-minute read.

## Minute 15–25 — Try the always-on skills

Open a Claude Code session in the repo and try:

### `/code-review`
Make a trivial change on a branch (rename a variable) then ask:
> "review my changes"

Severity-grouped findings should come back. If the skill didn't trigger, its description needs tightening (see §Adding a new skill).

### `/debug`
Break a known-good test intentionally, then ask:
> "this test is failing, can you figure out why"

Watch the skill walk the repro → failing-test → fix → regression loop.

### `/planning`
Pick a small feature idea:
> "plan how we'd add <feature>"

A structured plan should come back with surface area, steps, and risks.

### `/validate-and-fix`
Before committing anything:
> "validate and fix"

Auto-discovers your lint/typecheck/test, runs in parallel, categorizes findings (Critical/High/Medium/Low), and fixes what's auto-fixable.

## Minute 25–35 — The big-feature workflow: `/spec`

For anything larger than one session, use the three-stage spec workflow:

### Stage 1: `/spec:create <feature>`
Produces a detailed spec at `.claude/memory-bank/<branch>/specs/<feature>.md` — goal, non-goals, surface area, constraints, chosen approach, risks.

### Stage 2: `/spec:decompose <feature>`
Turns the spec into a task list where each task **copies the actual current code** it will modify (not a summary). Tasks are 20min–2hr each. Each is independently mergeable.

### Stage 3: `/spec:execute <feature> [task number]`
Executes one task. Each task is a checkpoint — you don't auto-advance.

Try it on a real feature. The three-stage workflow makes big changes feel like a series of small ones.

## Minute 35–50 — Dispatch the specialists

Still in the same session, hand off to subagents:

### Always-on specialists

```
"dispatch the reviewer subagent to do a read-only review of my branch"
```
The subagent runs in its own context. Its report comes back as structured findings. Your main session didn't pay the context cost of reading every file.

```
"dispatch the security-auditor to do a security pass on /src/auth"
```
OWASP-driven deeper-than-review pass. Flags injection, auth holes, crypto misuse, dependency CVEs.

```
"dispatch the refactoring-expert to clean up /src/orders following Fowler patterns"
```
Behavior-preserving incremental loop — tests stay green through every step.

```
"dispatch the researcher to find how we've handled rate limiting elsewhere in the codebase"
```
Reads docs, PRs, issues, external blogs. No code writes.

### Stack-gated specialists
If your stack tripped a gate, you'll also have:
- `accessibility-expert` — frontend projects. WCAG / ARIA / keyboard / screen reader audit.
- `design-reviewer` — frontend projects. UI/UX post-build review — states, responsive, polish.
- `database-expert` — projects with a DB driver. Query plans, index design, migration safety.
- `docker-expert` — projects with a Dockerfile. Multi-stage, caching, size, hardening.

Dispatch the relevant one when the work calls for it:
```
"dispatch database-expert to review this migration for safety"
"dispatch accessibility-expert on the new settings page"
```

## Minute 50–60 — Watch the hooks fire

The six hooks run automatically on tool-call lifecycle events. Try each:

### `file-guard` (PreToolUse, security)
Ask Claude to read `.env`:
> "read .env"

It should block: `file-guard: blocked access to sensitive path`. Shell pipelines like `find . -name ".env" | xargs cat` are blocked too.

### `pre-write-lint` (PreToolUse, quality)
Intentionally add a lint error (unused variable, bad import). Save.
The hook should block the write and surface the lint error.

### `check-code-quality` (PostToolUse, quality)
Replace a real function body with `// ...`. Save.
The hook should flag: `placeholder comment detected in additions`.

### `post-write-test` (PostToolUse, quality)
After editing a file with an adjacent test (`foo.ts` → `foo.test.ts`), the hook runs that test automatically.

### `create-checkpoint` (Stop, safety)
Every time a Claude session ends, a labeled `git stash` snapshot is created.
List them anytime:
```
"/checkpoint:list"
```
Or restore a specific one:
```
"/checkpoint:restore before-refactor"
```

### `session-summary` (Stop, log)
Structured session log written to `.claude/logs/session-YYYYMMDD.log`. Useful for figuring out what a past session actually did.

## Minute 60–75 — Stack-specific customization

Open these and tailor to your project:

- **`CLAUDE.md`** — architecture, folder conventions, non-negotiables, common gotchas. The more specific, the less Claude has to guess.
- **`.claude/skills/feature-implementation/references/architecture.md`** — describe your real layering (domain, infrastructure, presentation).
- **`.claude/skills/feature-implementation/references/api-conventions.md`** — your URL, error, pagination, auth conventions.
- **`.claude/skills/feature-implementation/references/testing-strategy.md`** — your test pyramid and naming conventions.

Every `feature-implementation` invocation loads only the references relevant to the change, so none of this is free context cost.

## Minute 75–90 — First real task, end to end

Pick a small real ticket and walk it through:

1. **`/planning`** or **`/spec:create`** depending on size
2. Dispatch `researcher` in parallel to pull any needed external context
3. **`/feature-implementation`** (or `/spec:execute`) to build
4. Hooks enforce lint + quality + adjacent tests on every save
5. Dispatch `test-runner` if tests go red
6. **`/validate-and-fix`** for the final sweep
7. Dispatch `reviewer` (and `security-auditor` if sensitive) for a self-review
8. **`/write-docs`** if CLAUDE.md, README, or ADRs need updates
9. **`/git:commit`** to land the work with a message that matches your repo style
10. **`/pr`** to open the pull request with structured body and test plan

Time it honestly against your pre-setup flow. You should be 3–5× faster on medium-complexity work.

## Adding a new skill

When you've typed a similar prompt 5+ times in two weeks, it's skill-worthy.

### 8-step process
1. **Identify.** Repeatable structure? Would a teammate benefit? If not, leave it as a prompt or put it in CLAUDE.md.
2. **Pick the primitive.**
   | Need | Primitive |
   |---|---|
   | Always-on context | CLAUDE.md or memory-bank |
   | Procedure triggered by keywords | Skill |
   | External system access | MCP server |
   | Isolated parallel work | Subagent |
   | Deterministic guarantee every tool use | Hook |
3. **Scaffold.** Install skill-creator plugin:
   ```
   /plugin marketplace add anthropics/skills
   /plugin install skill-creator
   /skill-creator new <name>
   ```
4. **Write the front-matter first.** The description is the ballgame. Be aggressive — list every plausible phrase a user might use. Polite descriptions under-trigger.
5. **Structure the body.** Overview, when to invoke, procedure, anti-patterns, output format. Under 500 lines. Longer content → `references/` or `scripts/`.
6. **Evaluate.** Write `evals.json` with 5–10 positive triggers and 5 negative. Aim for 100% positive / 0% negative.
7. **Commit.** Move from `~/.claude/skills/` (personal) to `.claude/skills/` (team). Add a line to CLAUDE.md.
8. **Retire skills that aren't pulling weight.** Check `.claude/logs/` for which fired. Dormant 60+ days → tighten or delete.

## Adding a new subagent

Drop a markdown file in `.claude/agents/<name>.md`:

```markdown
---
name: <name>
description: <when to dispatch — list every plausible phrase>
tools: <comma-separated tool list>
---

<instructions>
```

Restrict `tools` narrowly — read-only reviewers should have no write tools; a focused expert doesn't need web fetch.

If the agent is only relevant when a specific stack gate is tripped, put it in `.claude/agents/stack-gated/<category>/` and update `setup.sh` to copy it when detected.

## Adding a new hook

Edit `.claude/settings.json`:

```json
"PostToolUse": [
  { "matcher": "Write|Edit",
    "hooks": [{"type": "command", "command": ".claude/hooks/your-hook.sh"}] }
]
```

Lifecycle events: `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, `UserPromptSubmit`.

Exit codes:
- `0` — success, don't block
- `2` — block the tool call (PreToolUse only)

Keep hooks fast — they run on every tool call. Under 200ms is a reasonable ceiling.

## Memory-bank conventions

The four `CLAUDE-*.md` files at the repo root are your cross-session context:

| File | What goes in it | Update cadence |
|---|---|---|
| `CLAUDE-activeContext.md` | Current focus, in-flight branches, open questions, next up | Every work session |
| `CLAUDE-patterns.md` | Patterns used 2+ times worth codifying | When you catch a new pattern emerging |
| `CLAUDE-decisions.md` | ADR-lite log: why X over Y, consequences | When a decision is made |
| `CLAUDE-troubleshooting.md` | Weird bugs + fixes that took too long to find | After each painful debug |

**Say "update memory bank" to Claude** and it'll review and update them from the current session's context. Don't let them go stale — they're the difference between a long project that remembers itself and one that re-learns every session.

## Red flags that your setup isn't working

- You're copy-pasting code into a separate Claude chat window → Claude Code extension isn't set up.
- Claude keeps making the same project-specific mistake → CLAUDE.md is too vague.
- Your skills never auto-trigger → descriptions aren't pushy enough; look at `evals.json`.
- Main session regularly hits context limits → you're not dispatching subagents for heavy work.
- Tests sometimes get skipped → prompting for tests instead of enforcing with a hook.
- You keep trying to read `.env` by accident → that's `file-guard` working as intended.

## Where to learn more

- [`REFERENCES.md`](REFERENCES.md) — what this boilerplate stole from claudekit, centminmod, anthropics/skills, and others; and what's worth studying directly.
- Anthropic's official skills: `/plugin marketplace add anthropics/skills`
- [`PLUGINS.md`](PLUGINS.md) — other marketplaces worth pulling from
- [`MCP.md`](MCP.md) — connecting external systems (GitHub, Sentry, etc.)
