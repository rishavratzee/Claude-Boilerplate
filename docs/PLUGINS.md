# Recommended Claude Code plugins

This boilerplate ships with its own skills, agents, and hooks — selected for "substantial SDLC value only". Layer these plugins on for additional coverage when a project needs it.

> For patterns we *already ported* from specific repos (claudekit, centminmod, OneRedOak, etc.), see [REFERENCES.md](REFERENCES.md). This file is for plugins worth *installing on top*.

## Installing

```
/plugin marketplace add <owner>/<repo>
/plugin install <plugin-name>
/plugins                          # browse installed
```

## Essentials (install everywhere)

### anthropics/skills
Anthropic's official reference skills — including `skill-creator`, `mcp-builder`, and file-format skills (`pdf`, `docx`, `pptx`, `xlsx`). The gold standard for skill structure.

```
/plugin marketplace add anthropics/skills
/plugin install skill-creator
/plugin install mcp-builder
```

**Why:** `skill-creator` gives you the scaffold + eval framework for any new skill you author. `mcp-builder` scaffolds custom MCP servers.

### davila7/claude-code-templates
CLI tool that gives you à-la-carte access to 1000+ prebuilt agents, commands, settings, hooks, and MCPs.

```
npx claude-code-templates@latest
```

**Why:** great for filling gaps. Most components are generic persona prompts — cherry-pick only the ones that solve a real failure mode, not ones that look interesting.

## Workflow augmentation

These are worth adding if you have a specific need our default set doesn't cover.

### TDD Guard (`nizos/tdd-guard`)
PreToolUse hook that blocks writes violating red-green-refactor. Powerful but opinionated. We didn't ship it by default because not every project does TDD. Enable if yours does.

### Parry (`vaporif/parry`)
Prompt-injection / secret-exfiltration scanner that runs on tool inputs and outputs. Complements our `file-guard` with behavioral scanning. Add if your threat model includes adversarial inputs.

### Safety net (`kenryu42/cc-marketplace`)
Plugin that intercepts destructive git and filesystem operations. Complements our settings.json deny-list. Good as defense-in-depth.

### Design review workflow (OneRedOak)
We ported the `design-reviewer` agent pattern (stack-gated to frontend projects). The upstream version has additional integrations worth exploring if you need deep visual regression coverage.

## Reference / inspiration (read, don't necessarily install)

- `luongnv89/claude-howto` — learning path + template library
- `centminmod/my-claude-code-setup` — a real developer's full production setup, in public
- `carlrannaberg/claudekit` — 20+ specialist subagents, hooks, and commands; source of many of our hook patterns
- `hesreallyhim/awesome-claude-code` — the curated index of everything

## Our philosophy on plugins

1. **Fewer is better.** Every plugin adds a skill or agent that might mis-trigger. Audit quarterly.
2. **Prefer in-repo over plugin** for project-specific procedures. Plugins are great for universal patterns (review, debug) but anything tied to your stack/conventions belongs in `.claude/skills/` committed to the project.
3. **Read the SKILL.md before installing.** Especially descriptions — a plugin with vague descriptions will either under-trigger (useless) or over-trigger (noise).
4. **Check exec permissions.** Some plugins run scripts. Know what they run before enabling.
5. **SDLC-substantial or skip.** If a plugin doesn't own a real SDLC stage, it belongs in personal config, not team/project config.
