# claude-sdlc-boilerplate

A drop-in repo that turns any project — new or existing — into a Claude-augmented SDLC workbench. One script installs a curated `CLAUDE.md`, 13 trigger-tuned skills, 5 always-on subagents plus up-to-4 stack-gated specialists, 6 lifecycle hooks, a memory-bank file system, and an opinionated `settings.json`.

The goal: every new project feels like **a team of specialists is working alongside you** — a reviewer, a test-runner, a security auditor, a refactoring expert, a database expert, a researcher, a planner — rather than a single chat window you lean on reactively.

## What you get

| Piece | What it does |
|---|---|
| `CLAUDE.md` | Always-on project context. Stack, conventions, non-negotiables. Auto-filled from detected stack. |
| `.claude/settings.json` | Permissions, deny-lists for destructive ops, and six lifecycle hooks. |
| **13 skills** | All SDLC stages — plan, implement, test, review, debug, doc, commit, PR, maintain |
| **5 always-on subagents** | `test-runner`, `reviewer` (read-only), `researcher`, `refactoring-expert`, `security-auditor` |
| **Up to 4 stack-gated subagents** | `accessibility-expert` + `design-reviewer` (frontend), `database-expert` (DB), `docker-expert` (Dockerfile) |
| **6 hooks** | Security (file-guard), quality (lint, code-quality, adjacent-tests), recovery (checkpoint), summary |
| **Memory-bank** | `CLAUDE-activeContext.md`, `-patterns.md`, `-decisions.md`, `-troubleshooting.md` for cross-session memory |
| **Evals per skill** | `evals.json` with positive/negative trigger prompts for tuning descriptions |
| `setup.sh` | Idempotent installer. Detects TS/Node, Python, Go, Rust, plus frontend/DB/Docker gates. Merges safely with existing `CLAUDE.md` / `settings.json`. |

## The skill set

Every skill has an aggressive trigger description, an `evals.json` with positive/negative test prompts, and a procedure section.

| Skill | Covers | SDLC stage |
|---|---|---|
| `/planning` | Produce a plan before implementing | Planning |
| `/spec:create / decompose / execute` | Three-stage feature workflow with code-copy into tasks | Planning (big features) |
| `/ui-planner` | Component breakdown, state, flows, a11y, responsive | Design |
| `/feature-implementation` | End-to-end feature build with bundled references and scripts | Implementation |
| `/write-tests` | Unit, integration, e2e — with edge case enumeration | Testing |
| `/debug` | Strict repro → failing test → fix → regression loop | Debugging |
| `/validate-and-fix` | Auto-discover lint/typecheck/test, parallel run, categorize, fix | Quality gate |
| `/code-review` | Correctness, security, coverage, readability, severity-grouped | Review |
| `/write-docs` | READMEs, ADRs, runbooks, inline docs, API refs | Documentation |
| `/git:commit` | Read repo style, match convention, write specific commit message | Commit |
| `/pr` | Pre-flight lint/test, title/body/test-plan/rollback | Ship |
| `/checkpoint:create / restore / list` | Manual named git-stash snapshots | Safety |
| `/dependency-upgrade` | One-at-a-time safe bumps with changelog + suite | Maintenance |

## The subagent roster

### Always-on (installed in every target)

| Agent | Role | Tools |
|---|---|---|
| `test-runner` | Iterates failing tests until green, or stops and reports after 3 attempts | Read/Edit/Write/Bash |
| `reviewer` | Read-only self-review before PR; returns structured findings | Read-only |
| `researcher` | External-context gathering (docs, issues, prior PRs, blog posts) | Read + web |
| `refactoring-expert` | Fowler-style behavior-preserving incremental loop | Read/Edit/Bash |
| `security-auditor` | OWASP-driven deeper-than-review security pass | Read-only |

### Stack-gated (installer detects and installs only when applicable)

| Agent | Enabled when | Role |
|---|---|---|
| `accessibility-expert` | Frontend framework detected | WCAG/ARIA/keyboard/a11y tooling |
| `design-reviewer` | Frontend framework detected | UI/UX post-build review — states, responsive, polish |
| `database-expert` | DB driver detected in deps | Query plans, indexes, N+1, migration safety |
| `docker-expert` | `Dockerfile` or `compose.yml` present | Multi-stage, caching, image size, hardening |

## The hooks

| Hook | Lifecycle | What it guarantees |
|---|---|---|
| `file-guard.sh` | PreToolUse (Read/Edit/Write/Bash) | Blocks reads of `.env`, SSH keys, cloud creds — even through shell pipelines |
| `pre-write-lint.sh` | PreToolUse (Write/Edit) | Runs project linter on the file being edited; blocks on failure |
| `check-code-quality.sh` | PostToolUse (Write/Edit) | Flags `// ...` stubs, silent `any` types, `_foo` unused-param drift |
| `post-write-test.sh` | PostToolUse (Write/Edit) | Runs adjacent tests for the edited file |
| `create-checkpoint.sh` | Stop | Git-stash snapshot of working tree for recoverable sessions |
| `session-summary.sh` | Stop | Structured log of files changed + commits to `.claude/logs/` |

## Install

### Into an existing project
```bash
git clone <this repo> ~/code/claude-sdlc-boilerplate
cd /path/to/your/project
~/code/claude-sdlc-boilerplate/setup.sh .
```

### Into a fresh project
```bash
~/code/claude-sdlc-boilerplate/setup.sh --new ~/code/new-project
```

### Other modes
```bash
./setup.sh --dry-run <target>    # show what would happen
./setup.sh --force <target>      # overwrite existing settings.json (with backup)
./setup.sh --uninstall <target>  # clean removal (leaves memory-bank files)
```

The installer is **idempotent** — run it again after updates and it'll refresh the managed block of `CLAUDE.md` without clobbering your hand-written sections.

## Supported stacks (auto-detected)

| Stack | Detector | Defaults |
|---|---|---|
| TypeScript / Node | `package.json` | `pnpm`/`yarn`/`npm` from lockfile; ESLint for pre-lint |
| Python | `pyproject.toml` / `requirements.txt` | `pytest`, `ruff` |
| Go | `go.mod` | `go test ./...`, `gofmt`, `go vet` |
| Rust | `Cargo.toml` | `cargo test`, `cargo clippy` |
| Other | — | placeholders you fill in |

### Gates (trigger stack-gated agents)

| Gate | Trigger |
|---|---|
| Frontend | `react`, `vue`, `@angular`, `svelte`, `next`, `remix`, `nuxt`, `solid-js`, `preact`, `qwik`, `astro` in `package.json` |
| Database | Scoped `@prisma/*`, `@supabase/*`, `@planetscale/*`, `@drizzle-team/*`, or unscoped `pg/mysql/sqlite3/mongodb/mongoose/prisma/drizzle-orm/knex/typeorm` in Node; `psycopg/pymysql/sqlalchemy/pymongo/asyncpg/tortoise` in Python; `gorm/sqlx/pgx/go-sql-driver/mongo.org/bun/ent` in Go; `diesel/sqlx/rusqlite/tokio-postgres/mongodb/sea-orm` in Rust |
| Docker | `Dockerfile`, `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, or `compose.yaml` |

## How it's organized

```
claude-sdlc-boilerplate/
├── README.md                   <- you are here
├── setup.sh                    <- idempotent installer
├── CLAUDE.md.template          <- project-context, filled in per target
├── memory-bank-templates/      <- CLAUDE-activeContext / -patterns / -decisions / -troubleshooting
├── .claude/
│   ├── settings.json.template  <- permissions, 6 hooks, MCP allow-lists
│   ├── skills/                 <- 13 skills, each with evals.json
│   │   ├── code-review/        ├── feature-implementation/
│   │   ├── debug/              │   ├── references/
│   │   ├── write-tests/        │   ├── scripts/
│   │   ├── write-docs/         │   └── assets/
│   │   ├── planning/           ├── spec/
│   │   ├── ui-planner/         ├── validate-and-fix/
│   │   ├── git-commit/         ├── pr/
│   │   ├── checkpoint/         └── dependency-upgrade/
│   ├── agents/
│   │   ├── test-runner.md           <- always-on
│   │   ├── reviewer.md              <- always-on
│   │   ├── researcher.md            <- always-on
│   │   ├── refactoring-expert.md    <- always-on
│   │   ├── security-auditor.md      <- always-on
│   │   └── stack-gated/             <- copied to target only when detected
│   │       ├── frontend/            <- accessibility-expert, design-reviewer
│   │       ├── database/            <- database-expert
│   │       └── docker/              <- docker-expert
│   └── hooks/                  <- 6 lifecycle hooks (bash)
└── docs/
    ├── claude-onboarding.md    <- 90-min ramp for new devs
    ├── PLUGINS.md              <- recommended plugins & marketplaces
    ├── MCP.md                  <- MCP server setup reference
    └── REFERENCES.md           <- credits & what we ported from which repo
```

## How it works

### Skills are trigger-tuned
Every skill description lists every plausible phrase a user might use, so skills fire without the user having to remember to say `/debug` — they just say "it's broken" and `/debug` runs. See `evals.json` alongside each skill.

### Subagents have clean context
Dispatch `test-runner` to iterate on a red suite while your main session keeps planning the next feature. Dispatch `reviewer` (no write tools) for a read-only self-review. Dispatch `researcher` to pull external docs without polluting main context. Stack-gated experts only appear when they have something to do.

### Hooks are guarantees
The `PreToolUse` file-guard blocks credential reads even through shell pipelines. The `PostToolUse` check-code-quality hook flags lazy edits lint can't catch. The `Stop` create-checkpoint hook means every session has a recoverable restore point. These don't rely on Claude remembering — they run deterministically.

### Memory-bank survives sessions
Four files at the repo root — `CLAUDE-activeContext.md`, `-patterns.md`, `-decisions.md`, `-troubleshooting.md` — let long-running projects retain context across sessions that the single CLAUDE.md can't hold. Claude reads them on session start to know where to pick up.

### Safe merge
If your project already has `CLAUDE.md` or `.claude/settings.json`, the installer does not clobber them:
- **CLAUDE.md** — our content goes inside a `<!-- BEGIN CLAUDE-SDLC-BOILERPLATE -->` ... `<!-- END -->` block. Content outside the block is preserved on re-install.
- **settings.json** — if one exists, we write a `.proposed` file next to it and leave yours alone. Merge manually or pass `--force` to back up and overwrite.
- **Memory-bank files** — only written if they don't already exist; yours are never overwritten.

## Customize

Everything is a starting point. Common customizations:

| Want to... | Edit... |
|---|---|
| Change lint/test commands per project | `CLAUDE.md` and `.claude/settings.json` (auto-detected, tweak as needed) |
| Add a new skill | Follow the process in `docs/claude-onboarding.md` §Adding a new skill |
| Tighten or loosen a hook | `.claude/hooks/*.sh` — they're plain bash |
| Force the file-guard to allow a path | Set `FILE_GUARD_OVERRIDE=1` in your shell, or edit the patterns in `file-guard.sh` |
| Add per-project references for feature-implementation | `.claude/skills/feature-implementation/references/*.md` |
| Add a new scaffold template | `.claude/skills/feature-implementation/assets/` + update `scripts/scaffold_component.py` |
| Install stack-gated agents manually | `cp .claude/agents/stack-gated/<category>/*.md .claude/agents/` |
| Enable MCP servers (GitHub, Sentry, Playwright) | See `docs/MCP.md` |

## Philosophy

- **Substantial SDLC only.** Every primitive owns a real stage (safety, planning, implementation, review, commit, ship, maintenance). Cosmetic features belong in personal config, not per-project.
- **Progressive disclosure.** SKILL.md files stay under 500 lines. Large content lives in `references/` or `scripts/` and loads only when needed.
- **Aggressive triggers.** Polite skill descriptions fail silently — we list every plausible phrase.
- **Guarantees over prompts.** Anything you'd keep reminding Claude about belongs in a hook.
- **Context isolation.** Separate concerns into subagents so each has a clean window.
- **Stack-appropriate specialists.** A Go project shouldn't see `accessibility-expert`; a Rails project should see `database-expert`.

## Further reading

- [`docs/claude-onboarding.md`](docs/claude-onboarding.md) — 90-min ramp for yourself or a teammate
- [`docs/REFERENCES.md`](docs/REFERENCES.md) — credits to claudekit, centminmod, anthropics/skills, OneRedOak, and others, with notes on what we ported and what's worth studying
- [`docs/PLUGINS.md`](docs/PLUGINS.md) — plugins we recommend layering on
- [`docs/MCP.md`](docs/MCP.md) — MCP server setup (GitHub, Sentry, Playwright, custom)

## License

MIT. Fork freely.
