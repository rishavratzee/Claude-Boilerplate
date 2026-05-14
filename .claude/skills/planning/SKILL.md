---
name: planning
description: Produce a concrete implementation plan before writing any code — files to touch, order of operations, risks, rollout. Use this skill whenever the user asks to plan, design, spec, scope, break down, figure out how to approach, or strategize a feature, refactor, migration, or bugfix. Also trigger on "where do I start", "how should we tackle this", "what's the approach", "game plan for", "break this down", or when the user describes something larger than a single-file change.
---

# Planning

## When to invoke
Anything bigger than a single-file change. Migrations, refactors, new features, cross-cutting changes, incidents with unclear scope. Don't invoke for trivial edits.

## Procedure

### 1. Restate the goal
- One sentence, in the user's words, then your words. Confirm they match.
- If you can't state the goal crisply, you don't understand it yet — ask.

### 2. Find the relevant surface
- Grep/glob for every file that could be affected. Don't trust memory.
- Read the entry points (routes, CLI, handlers) to understand flow.
- Note existing abstractions you can reuse — don't re-invent.

### 3. Identify constraints
- Performance targets (latency, throughput)
- Compatibility (API versions, DB schema, client versions in the wild)
- Deadlines, freezes, dependencies on other teams
- Security/compliance requirements
- What must NOT change (public APIs, data formats, behavior clients depend on)

### 4. Enumerate approaches
- List 2-3 options, even if one is obvious. The obvious one is often wrong.
- For each: rough effort, main risk, what it forecloses.
- Pick one. State why the others lose.

### 5. Decompose into steps
- Each step is independently mergeable — it compiles, tests pass, it's not a half-state.
- Each step has: files touched, what changes, how to verify, estimated size (LOC or hours).
- Order matters: dependencies, risk up front, reversibility.

### 6. Call out risks explicitly
- What could go wrong? What's the blast radius if it does?
- What's the rollback plan for each step?
- What external signal tells you it's working in prod?

### 7. Validation plan
- How do you know it worked? Unit tests, integration tests, metrics, manual check.
- What's the acceptance criterion — the specific observation that proves done.

### 8. Persist the plan to MASTER-PLAN.md
Every plan produced by this skill **must** land in the repo's master roadmap so future sessions can pick it up. Mechanics:

1. **Check if `docs/plans/MASTER-PLAN.md` exists.**
   - **Yes** → propose adding this plan as a new "Pipeline" phase entry, OR (if the user is replacing/extending an existing in-progress phase) appending its tasks to that phase's task table. Show diff, confirm, write via the `roadmap-tracker` Capability 3 protocol (`.claude/skills/roadmap-tracker/references/status-update-protocol.md`).
   - **No** → bootstrap one. Use the template at `.claude/skills/roadmap-tracker/references/templates/master-plan-template.md`. Show the seeded file before writing. After bootstrap, add this plan as Phase 1 "In progress."
2. **Write the changelog entry.** Append to `docs/plans/.roadmap-tracker-changelog.md` recording: change type = `Phase added`, source = "produced by /planning", reason = the user's stated goal.
3. **Suggest a commit message** matching the repo's convention (sample `git log --oneline -10`). Default for plan-only writes:
   ```
   docs(plan): add Phase N — <name> (planning skill output)
   ```
4. **Hand off to the user** — point them at the next step (commit, then `/feature-implementation` or just start work).

If the user explicitly asks "don't update the master plan, just show me the plan" — skip Step 8. Otherwise, treat persistence as default behavior. The reason: a plan that lives only in chat context is lost the moment the session ends; a plan in `MASTER-PLAN.md` is recoverable, sharable, and survives compaction.

## Output format

```markdown
## Plan: <goal>

### Goal
<one sentence>

### Surface area
- <file or module 1>
- <file or module 2>

### Constraints
- <constraint 1>
- <constraint 2>

### Chosen approach
<approach name>. Considered <alt 1> (rejected because X), <alt 2> (rejected because Y).

### Steps
1. **<step name>** (~<size>)
   - Files: <paths>
   - Change: <what>
   - Verify: <how>
   - Rollback: <how>
2. ...

### Risks
- <risk>: <mitigation>

### Done when
- <observable criterion>
```

## Anti-patterns to avoid
- Plans that are just "I'll figure it out as I go."
- Skipping the surface-area step because "I know this code" — you don't, not this week.
- Bundling everything into one giant step to "save time" — it loses reviewability.
- Planning in the abstract without reading actual file paths and function names.
- Not stating what you're NOT doing. Scope cuts are part of the plan.

## Hand-off
Once the plan is approved by the user:
1. **Persist** to `docs/plans/MASTER-PLAN.md` per Step 8 above (default unless the user opts out).
2. **Implementation** is `/feature-implementation` (or just do it inline for small plans).
3. **Status updates** during execution flow through the `roadmap-tracker` skill — "mark T-N.X done" lands the diff in `MASTER-PLAN.md` automatically.

Keep the plan open as a reference — tick off steps as they land.
