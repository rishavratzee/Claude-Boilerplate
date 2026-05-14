---
name: ui-planner
description: Plan user interface and UX changes before coding — component breakdown, state shape, interaction flows, accessibility, responsive behavior. Use this skill whenever the user asks to design, mock up, plan, or think through a screen, page, component, form, dashboard, modal, or any UI. Also trigger on "how should this look", "wireframe this", "UX for X", "component breakdown", "design the flow for", or when the user is about to build UI without a plan.
---

# UI Planner

## When to invoke
Before writing any non-trivial UI code. Also when the user describes a user-facing feature without specifying component structure, state, or interaction model.

## Procedure

### 1. Understand the user job
- What is the user trying to accomplish? In one sentence, from their POV.
- What's the current flow (if any)? What's painful about it?
- What's the success state? What do they see/do when it worked?

### 2. Sketch the information architecture
- What data does the screen show? Where does it come from?
- What actions can the user take? What are their side effects?
- What navigation leads here, and where does it lead onward?

### 3. Component breakdown
For each screen/view:
- List components top-down, from page-level to leaf.
- Mark each as **new**, **reused**, or **modified**.
- For new components: name, purpose, props shape, state ownership.
- For reused: check they actually fit — don't force a mismatched reuse.

### 4. State shape
- What's local (component state)? What's shared (context/store)? What's server (fetched/mutated)?
- Optimistic updates? Loading states? Error states? Empty states?
- URL-driven state — what should be in the URL so refresh/share works?

### 5. Interaction flows
- Map every user action to its state transition.
- Include the failure paths — what does the user see when the network dies mid-action?
- Keyboard navigation — tab order, shortcuts, escape behavior.

### 6. Accessibility — non-negotiable
- Semantic HTML — use `<button>`, `<nav>`, `<main>`, not generic `<div>`.
- Keyboard operable — every interaction must work without a mouse.
- Screen reader — labels, ARIA where needed, focus management on route changes.
- Contrast — WCAG AA minimum (4.5:1 normal text).
- Motion — honor `prefers-reduced-motion`.

### 7. Responsive behavior
- Define breakpoints and what changes at each.
- What's the mobile-first minimum viable view?
- Touch targets (44x44px minimum).

### 8. Edge cases checklist
- Very long content (overflow, wrapping, truncation strategy)
- Very short content (empty states)
- Slow network (skeletons, not spinners, for known layouts)
- Offline
- RTL languages if relevant
- Zero results, one result, many results, pagination limits

### 9. Persist the UI plan to MASTER-PLAN.md
Every UI plan produced by this skill **must** land in the repo's master roadmap, on the **frontend track**, so future sessions and the `roadmap-tracker` skill can pick it up. Mechanics:

1. **Check if `docs/plans/MASTER-PLAN.md` exists.**
   - **Yes** → propose adding the UI plan as either:
     - A new "Pipeline" phase (if this is greenfield UI work, e.g. "design a new admin section")
     - Frontend-track tasks under an existing in-progress phase (most common — backend + frontend phases pair, e.g. T-N.j..T-N.n covering the FE side of an in-flight backend phase)
   - Show the diff, confirm, write via `roadmap-tracker` Capability 3 protocol (`.claude/skills/roadmap-tracker/references/status-update-protocol.md`).
   - **No** → bootstrap one using `.claude/skills/roadmap-tracker/references/templates/master-plan-template.md`. After bootstrap, add this UI plan as Phase 1's frontend track.
2. **Write the changelog entry.** Append to `docs/plans/.roadmap-tracker-changelog.md`: change type = `Phase added` or `Phase scope edit`, source = "produced by /ui-planner".
3. **Suggest a commit message:**
   ```
   docs(plan): add frontend tasks for Phase N — <feature> (ui-planner output)
   ```
4. **Hand off** — point the user at the next step (commit, then build per the component breakdown).

If the user explicitly says "don't update the master plan" — skip this step. Otherwise persistence is default. UI plans get lost in chat context fast; the master plan keeps them recoverable.

## Output format

```markdown
## UI plan: <feature>

### User job
<one sentence>

### Components
- **PageX** (new) — props: { ... }, owns: routeState
  - **HeaderY** (reused)
  - **FormZ** (new) — props: { ... }
    - ...

### State
- Local: ...
- Shared: ...
- Server: ...
- URL: ...

### Flows
1. User clicks Submit
   - Optimistic: mark item saved
   - On success: toast, close modal
   - On failure: rollback, inline error

### A11y notes
- ...

### Responsive
- Mobile: ...
- Tablet: ...
- Desktop: ...

### Edge cases
- ...
```

## Anti-patterns to avoid
- Jumping to pixel-perfect mocks before the flow is right.
- "We'll add a11y later" — retrofitting accessibility is 5× the cost of building it in.
- Global state for everything — most state is local.
- Designing only the happy path and calling it done.
- Reinventing components that already exist in the design system.
