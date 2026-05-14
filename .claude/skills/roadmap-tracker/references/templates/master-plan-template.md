# <PROJECT NAME> — Master Plan & Tracker

> **Purpose:** Single source of truth for what's shipped, what's in progress, what's pipelined, and who owns each piece. Read this first when checking project status.
> **Last updated:** YYYY-MM-DD
> **Owner of this doc:** <NAME>. Update on every phase boundary.
> **Tracking note:** <"tracked in git" or "lives in docs/plans/ which is gitignored — local working artifact">
> **Related docs:**
> - `docs/plans/phase-roadmap.md` — full forward plan
> - `docs/specs/*.md` — per-phase design docs
> - `docs/handoff/*.md` — phase handoff docs

---

## Status dashboard

| Phase | Name | Status | Tasks done | Last commit | Owner |
|---|---|---|---|---|---|
| 1 | <name> | ✅ Shipped | All | YYYY-MM-DD | <name> |
| 2 | <name> | ⏳ In progress | X/Y | hash | <name> |
| 3 | <name> | 📋 Pipeline | 0/Y | — | <name> |
| 4 | <name> | 📋 Backlog | 0/Y | — | TBD |
| 5+ | Future (reserved) | 📋 Reserved | — | — | — |

**Critical path remaining:** ~Xw at one BE + one FE engineer.

---

## Roles & contributors

| Person | Role | What they do |
|---|---|---|
| <name> | Implementation engineer (TZ) | <responsibility> |
| <name> | Planning + product | <responsibility> |
| <name> | Cross-team coordinator (Phase X) | <responsibility> |

**Git attribution note:** <how git author maps to physical author, if non-obvious>

---

## Done — Phase 1 through N

### Phase 1 — <name> (shipped YYYY-MM-DD)
**By:** <name>
**Achievement:** <one paragraph, user-facing terms>
**Tasks:** T-1.1 → T-1.N
**Key commits:**
- `hash` T-1.X — <one-liner>
- ...

### Phase 2 — <name> (shipped YYYY-MM-DD)
... same shape ...

---

## In progress — Phase N (<name>)

**By:** <name>
**Started:** YYYY-MM-DD
**Spec:** `docs/specs/<spec>.md`
**Achievement target:** <one paragraph>

**Progress: X of Y tasks done.**

| Task | Status | Commit | Time | What landed |
|---|---|---|---|---|
| T-N.a | ✅ | hash | HH:MM | <one-liner> |
| T-N.b | ⏳ Next | — | — | <description> |
| T-N.c | 📋 | — | — | <description> |
| ... | | | | |

**Test posture:** X green (was Y baseline; +Δ net Phase N tests).

**Remaining estimate:** ~Xh focused work, likely Y working days.

**Phase N exit criteria:**
- [ ] All tasks committed
- [ ] All tests green
- [ ] Manual smoke: <criteria>
- [ ] Update MASTER-PLAN.md "In progress" → "Done"

---

## Pipeline — Phase N+1 through M

### Phase N+1 — <name>
**Owner:** <name> (planned)
**Size:** ~Xw
**Achievement:** <one paragraph>
**Why next:** <reasoning>
**Tasks:** T-(N+1).a → T-(N+1).Z (count). Detail in `docs/plans/phase-roadmap.md`.
**Dependencies:** Phase N.

### Phase N+2 — <name>
... same shape ...

---

## Critical-path summary

To realize <milestone>: ~Xw at one BE + one FE engineer working sequentially.

| Phase | Weeks | Cumulative |
|---|---|---|
| N | X | X |
| N+1 | Y | X+Y |
| ... | | |

---

## Open decisions

| # | Decision | Where | Impacts |
|---|---|---|---|
| D1 | <decision text> | `docs/specs/<file>.md` §X | Phase N |
| D2 | <decision text> | <where> | Phase M |
| ... | | | |

---

## Maintenance protocol

Update this file when:
1. **A task lands** — flip status icon, fill commit hash + time, update test count.
2. **A phase completes** — move from "In progress" to "Done"; promote next phase from "Pipeline" to "In progress."
3. **A decision changes** — update open-decisions table; cross-reference the spec change.
4. **Owner changes** — update roles table.

Keep the dashboard at the top accurate above all else.
