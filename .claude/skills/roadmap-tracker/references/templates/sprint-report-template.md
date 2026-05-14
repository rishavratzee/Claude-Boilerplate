# Sprint report — <PROJECT> — <YYYY-MM-DD to YYYY-MM-DD>

> **Window:** <N> calendar days
> **Generated:** YYYY-MM-DD by roadmap-tracker
> **Reporting period commits:** N total

## TL;DR

<2–3 sentences. What shipped, what's in flight, what's blocked. The kind of update an exec would skim.>

---

## Shipped this sprint

### Phase N — <name> tasks

| Task | Commit | Date | Time | What landed |
|---|---|---|---|---|
| T-N.a | `hash` | YYYY-MM-DD | HH:MM TZ | <one-liner> |
| T-N.b | `hash` | YYYY-MM-DD | HH:MM TZ | <one-liner> |

### Phase M — <name> tasks
... if multi-phase progress ...

### Other commits (chores, docs, fixes)
- `hash` <one-liner>
- `hash` <one-liner>

---

## In flight (not yet shipped)

| Task | Status | Started | Owner | Blocker (if any) |
|---|---|---|---|---|
| T-N.c | ⏳ In progress | YYYY-MM-DD | <name> | None |
| T-N.d | 📋 Next | — | <name> | Waiting on T-N.c |

---

## Blockers + decisions needed

- <blocker>: <description, what's needed to unblock, who owns>
- <decision needed>: <what's the choice + by when>

If empty: "None."

---

## Test posture

- Backend: X green (Δ from sprint start: +Y new tests)
- Frontend: X green (Δ: +Y)
- Coverage on changed files: ≥X%
- Lint / typecheck: clean / N pre-existing errors (unchanged)

---

## Contributor activity

| Person | Commits | Focused hours (est. from commit windows) | Phases touched |
|---|---|---|---|
| <name> | N | ~Xh | Phase N |
| <name> | N | ~Yh | Phase N+1 |

**Estimation method:** sum of windows between consecutive commits within an active session (gap > 90 min splits sessions). Times in the implementer's local timezone.

---

## Next sprint plan

**Carry-over:**
- T-N.c through T-N.X (current Phase N tail)

**New starts:**
- Phase N+1 if Phase N exits this sprint, starting T-(N+1).a
- ...

**Cross-team / external dependencies coming up:**
- <thing>: <when needed by + who owns>

---

## Looking back: what worked, what didn't

(Optional — skip if nothing notable. The roadmap-tracker fills this from CHANGELOG entries marked with `Reason:` notes during the sprint.)

- ✓ <thing that went well>
- ✗ <thing that slowed us / decision we'd revisit>

---

## Pointers

- Master plan: `docs/plans/MASTER-PLAN.md`
- Phase roadmap: `docs/plans/phase-roadmap.md`
- Active phase spec: `docs/specs/<spec>.md`
- Active handoff: `docs/handoff/<handoff>.md`
