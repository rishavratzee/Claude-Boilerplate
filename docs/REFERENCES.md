# References — where the patterns came from

This boilerplate stands on the shoulders of several open-source Claude Code setups. Each repo below is credited, with a note on what we absorbed and what's worth studying directly.

## Repos whose patterns we ported

### [carlrannaberg/claudekit](https://github.com/carlrannaberg/claudekit)
Production-grade CLI toolkit with 20+ specialist subagents, hooks, and slash commands. The most directly plundered source in this boilerplate.

**Ported from claudekit:**
- `file-guard` PreToolUse hook (`.claude/hooks/file-guard.sh`) — blocks reads of `.env`, keys, cloud creds, including through shell pipelines
- `create-checkpoint` Stop hook (`.claude/hooks/create-checkpoint.sh`) + `/checkpoint` slash command — git-stash snapshots on every Stop
- `check-code-quality` PostToolUse hook (`.claude/hooks/check-code-quality.sh`) — catches `// ...` stubs, silent `any` types, underscored-param drift
- `refactoring-expert` subagent — Fowler-style behavior-preserving loop
- `/spec:create / decompose / execute` workflow — three-stage feature pipeline with code-copy into tasks
- `/validate-and-fix` skill — auto-discover lint/typecheck/test, parallel run, categorize, fix
- `/git:commit`, `/pr` skills — conv-commit aware, repo-style matching
- `database-expert`, `docker-expert`, `accessibility-expert` patterns — specialist subagents

**What else is worth studying in claudekit:**
- `claudekit doctor` maintenance command
- `thinking-level` UserPromptSubmit hook
- `oracle` second-opinion agent (gpt-5 backed; we skipped due to external dep)
- Hook profiling (`claudekit-hooks profile`) — surfaces slow hooks
- Per-subagent `disableHooks` config — kill switch per agent

### [centminmod/my-claude-code-setup](https://github.com/centminmod/my-claude-code-setup)
A real developer's production setup, committed in public. Dense with patterns.

**Ported from centminmod:**
- Memory-bank file system — `CLAUDE-activeContext.md`, `CLAUDE-patterns.md`, `CLAUDE-decisions.md`, `CLAUDE-troubleshooting.md` with an `update memory bank` convention. Installed by setup.sh into every target.

**What else is worth studying:**
- Statusline script (context/cost/worktree/ahead-behind in the prompt bar)
- `clx`/`cx` git-worktree launcher functions
- "Faster tools" block redirecting `grep`/`find` to `rg`/`fd`
- Progressive README variants (v2, v3, v4) for audience segmentation
- `claude-code-safety-net` plugin from `kenryu42/cc-marketplace`

### [anthropics/skills](https://github.com/anthropics/skills)
Anthropic's official reference skills. The canonical source for skill structure and the `skill-creator` eval framework.

**Pattern used throughout this boilerplate:**
- Progressive disclosure layout (SKILL.md < 500 lines, with `references/`, `scripts/`, `assets/` loaded on-demand) — our `feature-implementation` skill follows this exactly
- Aggressive trigger descriptions — all our skills list explicit trigger phrases per the skill-creator convention
- Bundled scripts for deterministic work — `scaffold_component.py`, `validate_migration.sh`, `check_coverage.py`

**Worth installing directly as a plugin marketplace:**
```
/plugin marketplace add anthropics/skills
/plugin install skill-creator
/plugin install mcp-builder
```

## Repos to study (not ported, but worth knowing about)

### [luongnv89/claude-howto](https://github.com/luongnv89/claude-howto)
Organized as a learning path + template library. Good for exploring primitives; mostly generalist content that overlaps with what we ship. Notable: mermaid diagrams per primitive, self-assessment slash commands.

### [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates)
CLI tool (`npx claude-code-templates@latest`) exposing 1000+ prebuilt agents, commands, hooks, MCPs. Most components are generic persona prompts; cherry-pick only the ones that solve a real failure mode.

### [tony/claude-code-riper-5](https://github.com/tony/claude-code-riper-5)
RIPER workflow (Research → Innovate → Plan → Execute → Review). Opinionated phase-gated mode system with branch-aware memory bank. We skipped it because it competes with our existing `/planning` + `/spec` workflow, but the branch-aware memory bank idea is the foundation of what we implemented.

### [OneRedOak/claude-code-workflows](https://github.com/OneRedOak/claude-code-workflows)
Source of the Design Review pattern. Our `design-reviewer` agent (stack-gated to frontend projects) descends from this.

### [nizos/tdd-guard](https://github.com/nizos/tdd-guard)
PreToolUse hook that blocks writes violating red-green-refactor. Powerful but opinionated — we didn't ship it because not every project does TDD; consider installing if yours does.

### [vaporif/parry](https://github.com/vaporif/parry)
Prompt-injection / secret-exfiltration scanner that runs on tool inputs and outputs. Complements our `file-guard` hook with behavioral scanning. Consider adding if your threat model includes adversarial inputs.

### [kenryu42/cc-marketplace](https://github.com/kenryu42/cc-marketplace)
Hosts `claude-code-safety-net` — a plugin that intercepts destructive git and filesystem operations. Complements our settings.json deny-list. Good as a defense-in-depth add-on.

## Discovery hubs

### [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
The curated index. Browse this when looking for specific workflows, patterns, or tools not covered here.

### [aitmpl.com](https://aitmpl.com)
Web UI for davila7's template registry. Useful for browsing specialists à la carte.

## What we deliberately didn't ship

- **`oracle` agent (claudekit)** — requires an OpenAI dep.
- **`github-actions-expert` (claudekit)** — marginal win over a generalist.
- **RIPER mode-gated workflow (Tony Narlock)** — heavyweight rewrite; competes with existing planning.
- **Framework-expert-per-framework (claudekit, davila7)** — 5-15k tokens for generalist-with-topic-prompt agents; add manually if a project justifies it.
- **TDD Guard (nizos)** — too opinionated; ship behind `TDD_GUARD=1` if you want it.
- **Statusline (centminmod)** — cosmetic; install personally, not per-project.
- **`clx`/`cx` worktree launcher (centminmod)** — workflow convenience; belongs in personal shell config, not per-project.
- **skill-creator closed-loop eval harness (anthropics)** — complex for unclear ROI; our static `evals.json` is enough to start.

## How we decide what to absorb

A pattern earns a slot in this boilerplate if it passes all three:

1. **Solves a failure mode the generalist can't.** Not "nicer version of what we have."
2. **SDLC-substantial.** Touches a real stage: safety, planning, implementation, review, commit, ship, or maintenance. Cosmetic features go in personal config.
3. **Low coupling.** Ports cleanly without dragging in a toolchain (TypeScript runtime, OpenAI key, specific framework).

Patterns that don't pass all three land in this file as "worth studying" — so the user can still reach them when the project needs them.
