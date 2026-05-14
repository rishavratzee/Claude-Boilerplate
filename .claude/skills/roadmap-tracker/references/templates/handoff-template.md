# Handoff: Phase N — <Phase name>

> **For:** <recipient>
> **From:** <author> (via Claude session, YYYY-MM-DD)
> **Repo state at handoff:** <branch + last commit hash + one-liner about state>
> **Read this in this order:**
> 1. §1–§3 of this doc (executive context + what each phase achieves) — 5 min
> 2. `docs/plans/phase-roadmap.md` (the full forward plan) — 10 min
> 3. `docs/specs/<relevant spec>.md` — 10 min
> 4. §4 of this doc (Phase N task-by-task) — start work

---

## 1. Executive context (why this work matters)

<2–3 paragraphs framing the business outcome this phase enables. Connect back to the user's stated goal / the executive vision. Don't restate the spec — frame the *why*.>

The product outcome the executive wants: **<one-line summary of vision>**.

The named **critical** items relevant to this phase:
- <item> — <status: shipped / in this phase / future>
- ...

---

## 2. Where Phase 1 through N-1 left us

<One-paragraph summary of what's already shipped and what's still missing. Connect each to a phase number so the recipient can navigate the master plan.>

**What's missing:**
- <gap> — addressed in Phase N
- <gap> — addressed in Phase N+1
- ...

---

## 3. What each phase achieves (user-facing terms)

| Phase | What a user can do after this ships | Why it's ordered here |
|---|---|---|
| **N — <name>** | <user-facing achievement> | <rationale for ordering> |
| N+1 — <name> | ... | ... |
| N+2 — <name> | ... | ... |
| N+3 — <name> | ... | ... |

---

## 4. Phase N — task-by-task (start here)

**Target:** ~Xw for one engineer.
**Design doc:** `docs/specs/<spec>.md` is canonical. Read sections X (data model), Y (API surface), Z (edge cases) before starting.
**Branch convention:** match prior phases — task-per-commit on `<branch>`, commit message `feat(<area>): <one-line> — task T-N.X`.

### Backend tasks

#### T-N.a — <one-line title>
**Files:** `<paths>`
**Spec ref:** <doc> §X.
**Change:** <2–4 sentences describing what to do>
**Verify:** <command + assertion>
**Size:** ~Xh.

#### T-N.b — ...
... same shape ...

### Frontend tasks

#### T-N.j — ...
... same shape ...

### Phase N exit checklist (paste into the PR)
- [ ] Migration up + down idempotent (if any).
- [ ] All tasks committed; commit messages follow convention.
- [ ] Backend: `<test command>` green; coverage ≥X%.
- [ ] Frontend: `<test command>` green.
- [ ] Lint / typecheck / format clean.
- [ ] Manual smoke (record in PR description):
  1. <step>
  2. <step>
- [ ] Update `MASTER-PLAN.md` "In progress" → "Done"; promote Phase N+1.

---

## 5. Phase N+1 — <name> (sketch, ~Xw)

**Achieves:** <user-facing one-paragraph>

**Why it's quick / hard / next:** <rationale>

**Tasks (target):**
- T-(N+1).a — <one-liner>
- T-(N+1).b — ...
- ...

**Reference:** mirror `<existing similar pattern>`.

---

## 6. Phase N+2 — <name> (sketch, ~Xw)

... same shape ...

---

## 10. Decisions still open (flag if you disagree)

These were made during planning and are baked into the spec docs. If any look wrong, push back before T-N.a lands:

| # | Decision | Where |
|---|---|---|
| D1 | <decision> | `docs/specs/<file>.md` §X |
| D2 | <decision> | <where> |
| ... | | |

---

## 11. Where to ask questions

- **Anything in the planning docs:** ping <name>.
- **Cross-team integration:** needs a kickoff with <team>; do not start <task> without it.
- **<Specific concern>:** <person / context>.

## 12. What this handoff does NOT cover

- <out-of-scope item>
- <out-of-scope item>

---

**Recommended kickoff:** read §1–§3 + `docs/plans/phase-roadmap.md` + `docs/specs/<spec>.md` (~30 min total), then start T-N.a.
