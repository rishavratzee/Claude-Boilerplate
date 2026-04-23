# MCP server setup

MCP (Model Context Protocol) servers give Claude actual tools — GitHub API access, Sentry error reads, Playwright browser control, database reads, etc. Set them up once per machine or per workspace.

## Which MCPs pair with which specialists

Each subagent in this boilerplate is more useful with the right MCP wired up.

| Specialist | Pairs best with | What becomes possible |
|---|---|---|
| `researcher` | GitHub, web fetch (built-in) | Reads upstream issues, PRs, docs, RFCs |
| `reviewer` | GitHub | Can post review comments directly to the PR |
| `security-auditor` | Sentry, dependency scanners | Reads recent errors; runs CVE scans against deps |
| `database-expert` | Postgres / MySQL (staging only) | Runs real `EXPLAIN ANALYZE` instead of reading SQL statically |
| `design-reviewer` | Playwright | Opens the actual page at multiple viewports; screenshots states |
| `accessibility-expert` | Playwright + axe-core | Runs automated a11y audits against live pages |
| `docker-expert` | (local docker daemon via shell) | `docker history`, `dive`, `trivy` on built images |
| `debug` skill | Sentry, Playwright | Reads error → reproduces in browser → writes fix |

## How MCP registration works

MCP servers are registered in `.claude/settings.json` under `mcpServers`. Per-user servers go in `~/.claude/settings.json`. Workspace-scoped servers live in the repo.

Every MCP server should have a clear scope (workspace vs global) and a deny-list of tools you don't want Claude to call autonomously.

## Recommended MCP servers

### GitHub
Read/write repos, PRs, issues, comments. Critical for closing the PR loop.

```
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

Then set `GITHUB_TOKEN` in your env (scoped PAT, minimum perms).

**What Claude can do:** open PRs, leave comments, read issues, check CI status.
**What Claude should NOT do without review:** merge PRs, close issues, force push.

### Sentry (or your error tracker)
Read recent errors, stack traces, breadcrumbs. Pairs beautifully with `/debug` and `security-auditor`.

```
claude mcp add sentry -- npx -y @modelcontextprotocol/server-sentry
```

Set `SENTRY_AUTH_TOKEN` and project info.

### Playwright
Headless browser control. Essential for UI feature implementation, E2E debugging, and the `design-reviewer` + `accessibility-expert` agents.

```
claude mcp add playwright -- npx -y @modelcontextprotocol/server-playwright
```

### Postgres / database
Read-only access to a staging or dev DB. Great for `/debug`, and essential for making `database-expert` non-speculative.

**Never point at prod.** Scope strictly.

```
claude mcp add postgres-staging -- npx -y @modelcontextprotocol/server-postgres "$STAGING_DB_URL"
```

### Custom internal MCP
Build your own for: internal APIs, deployment systems, feature flags, billing backends.

Scaffold with:
```
/plugin install mcp-builder
```
from the `anthropics/skills` marketplace, then follow the prompts. You'll get a working server scaffold in Python or TypeScript that you extend with 50–100 lines of your logic.

## MCP chaining example

A real workflow that threads three servers and two skills:

```
Sentry MCP reads the top error in the last 24h
  → GitHub MCP finds the commit that introduced the regression (git blame)
    → Playwright MCP reproduces the issue in a browser
      → /debug skill writes the fix and a regression test
        → reviewer subagent does a self-review
          → GitHub MCP opens the PR via /pr skill
```

Wire this up by having the main session drive it; Claude handles the control flow.

## Security — non-negotiable

- **Scope tightly.** Don't give `admin:org` when `repo:status` will do.
- **Never connect to prod databases.** Use staging/read replicas.
- **Per-workspace allow-lists.** `.claude/settings.json` should list exactly which MCPs are allowed.
- **Secrets in env, not in settings.json.** The settings file gets committed; env doesn't. Our `file-guard` hook also blocks reads of `.env`/`.aws/credentials`/SSH keys, so even an MCP going rogue can't easily exfiltrate them.
- **Rotate tokens on team member offboarding.** MCP tokens are long-lived.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| MCP not showing up in Claude Code | Server not registered for the current scope — check `claude mcp list` |
| "connection refused" on MCP call | Server binary not installed or `$PATH` issue |
| Claude won't use the MCP | Description too vague — try explicit prompt like "use the github MCP to..." |
| Credentials expired | Rotate and re-register the server |
| `file-guard` blocked an MCP read | If legitimate, set `FILE_GUARD_OVERRIDE=1` for the session, or adjust patterns in `.claude/hooks/file-guard.sh` |
