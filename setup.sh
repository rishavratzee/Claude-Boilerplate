#!/usr/bin/env bash
# claude-sdlc-boilerplate installer
#
# Usage:
#   ./setup.sh <target-dir>           # install into an existing project
#   ./setup.sh --new <target-dir>     # mkdir + install a fresh repo
#   ./setup.sh --dry-run <target-dir> # show what would happen, change nothing
#   ./setup.sh --force <target-dir>   # overwrite files that exist (with backup)
#   ./setup.sh --uninstall <target-dir>
#
# Idempotent: running twice is safe. Existing CLAUDE.md is merged via markers;
# existing settings.json is backed up and merged if jq is available.

set -euo pipefail

# ---------- paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- args ----------
MODE="install"
DRY_RUN=0
FORCE=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --new) MODE="new"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    -*)
      echo "unknown flag: $1" >&2
      exit 2
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        echo "unexpected arg: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "usage: $0 [--new|--dry-run|--force|--uninstall] <target-dir>" >&2
  exit 2
fi

# Resolve target to an absolute path.
if [[ "$MODE" = "new" ]]; then
  if [[ -e "$TARGET" && "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
    echo "--new: target exists and is not empty: $TARGET" >&2
    exit 1
  fi
  mkdir -p "$TARGET"
fi

if [[ ! -d "$TARGET" ]]; then
  echo "target is not a directory: $TARGET" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

# ---------- logging helpers ----------
blue()   { printf "\033[0;34m%s\033[0m\n" "$*"; }
green()  { printf "\033[0;32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$*"; }
red()    { printf "\033[0;31m%s\033[0m\n" "$*" >&2; }

action() {
  if [[ "$DRY_RUN" = "1" ]]; then
    yellow "[dry-run] $*"
  else
    blue "-> $*"
  fi
}

do_cmd() {
  if [[ "$DRY_RUN" = "1" ]]; then
    yellow "[dry-run] would run: $*"
  else
    eval "$@"
  fi
}

# ---------- uninstall ----------
if [[ "$MODE" = "uninstall" ]]; then
  blue "== uninstall from $TARGET =="
  # Remove the boilerplate block from CLAUDE.md, leave user content.
  if [[ -f "$TARGET/CLAUDE.md" ]]; then
    action "strip boilerplate block from CLAUDE.md"
    if [[ "$DRY_RUN" != "1" ]]; then
      awk '
        /<!-- BEGIN CLAUDE-SDLC-BOILERPLATE -->/ { skip=1; next }
        /<!-- END CLAUDE-SDLC-BOILERPLATE -->/   { skip=0; next }
        !skip { print }
      ' "$TARGET/CLAUDE.md" > "$TARGET/CLAUDE.md.new"
      mv "$TARGET/CLAUDE.md.new" "$TARGET/CLAUDE.md"
    fi
  fi
  for d in ".claude/skills" ".claude/agents" ".claude/hooks"; do
    if [[ -d "$TARGET/$d" ]]; then
      action "remove $d"
      do_cmd "rm -rf '$TARGET/$d'"
    fi
  done
  # settings.json — we restore from backup if present, else leave alone
  if [[ -f "$TARGET/.claude/settings.json.pre-boilerplate" ]]; then
    action "restore settings.json from pre-install backup"
    do_cmd "mv '$TARGET/.claude/settings.json.pre-boilerplate' '$TARGET/.claude/settings.json'"
  fi
  # Leave memory-bank files (CLAUDE-*.md) in place — they likely contain user content
  for f in CLAUDE-activeContext.md CLAUDE-patterns.md CLAUDE-decisions.md CLAUDE-troubleshooting.md; do
    if [[ -f "$TARGET/$f" ]]; then
      yellow "memory-bank file $f left in place (may contain your content). Delete manually if unwanted."
    fi
  done
  green "uninstall complete"
  exit 0
fi

# ---------- stack detection ----------
# Sets globals directly: STACK, LANGUAGE, FRAMEWORK, PKG_MGR, TEST_RUNNER,
# LINTER, CI, TEST_CMD, LINT_CMD, BUILD_CMD, INSTALL_CMD, DEV_CMD.
detect_stack() {
  if [[ -f "$TARGET/package.json" ]]; then
    STACK="node"
    LANGUAGE="JavaScript/TypeScript"
    if grep -q '"typescript"' "$TARGET/package.json" 2>/dev/null; then
      LANGUAGE="TypeScript"
    fi
    if grep -q '"next"' "$TARGET/package.json" 2>/dev/null; then
      FRAMEWORK="Next.js"
    elif grep -q '"react"' "$TARGET/package.json" 2>/dev/null; then
      FRAMEWORK="React"
    elif grep -q '"express"' "$TARGET/package.json" 2>/dev/null; then
      FRAMEWORK="Express"
    else
      FRAMEWORK="Node"
    fi

    if [[ -f "$TARGET/pnpm-lock.yaml" ]]; then
      PKG_MGR="pnpm"
    elif [[ -f "$TARGET/yarn.lock" ]]; then
      PKG_MGR="yarn"
    else
      PKG_MGR="npm"
    fi

    TEST_CMD="$PKG_MGR test"
    LINT_CMD="$PKG_MGR run lint"
    BUILD_CMD="$PKG_MGR run build"
    INSTALL_CMD="$PKG_MGR install"
    DEV_CMD="$PKG_MGR run dev"

  elif [[ -f "$TARGET/pyproject.toml" || -f "$TARGET/setup.py" || -f "$TARGET/requirements.txt" ]]; then
    STACK="python"
    LANGUAGE="Python"
    FRAMEWORK="Python"
    if grep -qE 'fastapi' "$TARGET/pyproject.toml" "$TARGET/requirements.txt" 2>/dev/null; then
      FRAMEWORK="FastAPI"
    elif grep -qE 'django|Django' "$TARGET/pyproject.toml" "$TARGET/requirements.txt" 2>/dev/null; then
      FRAMEWORK="Django"
    elif grep -qE 'flask|Flask' "$TARGET/pyproject.toml" "$TARGET/requirements.txt" 2>/dev/null; then
      FRAMEWORK="Flask"
    fi

    if [[ -f "$TARGET/poetry.lock" ]]; then
      PKG_MGR="poetry"
      INSTALL_CMD="poetry install"
    elif [[ -f "$TARGET/uv.lock" ]]; then
      PKG_MGR="uv"
      INSTALL_CMD="uv sync"
    else
      PKG_MGR="pip"
      INSTALL_CMD="pip install -r requirements.txt"
    fi

    TEST_CMD="pytest"
    LINT_CMD="ruff check ."
    BUILD_CMD="python -m build"
    DEV_CMD="# fill in dev run command"

  elif [[ -f "$TARGET/go.mod" ]]; then
    STACK="go"
    LANGUAGE="Go"
    FRAMEWORK="Go"
    PKG_MGR="go"
    TEST_CMD="go test ./..."
    LINT_CMD="go vet ./..."
    BUILD_CMD="go build ./..."
    INSTALL_CMD="go mod download"
    DEV_CMD="go run ./..."

  elif [[ -f "$TARGET/Cargo.toml" ]]; then
    STACK="rust"
    LANGUAGE="Rust"
    FRAMEWORK="Rust"
    PKG_MGR="cargo"
    TEST_CMD="cargo test"
    LINT_CMD="cargo clippy"
    BUILD_CMD="cargo build --release"
    INSTALL_CMD="cargo fetch"
    DEV_CMD="cargo run"

  else
    STACK="unknown"
    LANGUAGE="TODO-fill-in"
    FRAMEWORK="TODO-fill-in"
    PKG_MGR="TODO-fill-in"
    TEST_CMD="TODO-fill-in"
    LINT_CMD="TODO-fill-in"
    BUILD_CMD="TODO-fill-in"
    INSTALL_CMD="TODO-fill-in"
    DEV_CMD="TODO-fill-in"
  fi

  TEST_RUNNER="$PKG_MGR"
  LINTER="$PKG_MGR"
  CI="TODO-fill-in"

  # Stack-gate detection for specialist agents
  HAS_FRONTEND=0
  HAS_DATABASE=0
  HAS_DOCKER=0

  if [[ -f "$TARGET/Dockerfile" || -f "$TARGET/docker-compose.yml" || -f "$TARGET/docker-compose.yaml" || -f "$TARGET/compose.yml" || -f "$TARGET/compose.yaml" ]]; then
    HAS_DOCKER=1
  fi

  case "$STACK" in
    node)
      if grep -qE '"(react|vue|@angular|svelte|next|remix|nuxt|solid-js|preact|qwik|astro)"' "$TARGET/package.json" 2>/dev/null; then
        HAS_FRONTEND=1
      fi
      if grep -qE '"(pg|mysql|mysql2|sqlite3|better-sqlite3|mongodb|mongoose|prisma|drizzle-orm|knex|typeorm)"' "$TARGET/package.json" 2>/dev/null \
         || grep -qE '"@(prisma|supabase|planetscale|drizzle-team)/' "$TARGET/package.json" 2>/dev/null; then
        HAS_DATABASE=1
      fi
      ;;
    python)
      if grep -qE '(psycopg|pymysql|sqlalchemy|mongoengine|pymongo|sqlite3|asyncpg|tortoise)' "$TARGET/pyproject.toml" "$TARGET/requirements.txt" "$TARGET/setup.py" 2>/dev/null; then
        HAS_DATABASE=1
      fi
      ;;
    go)
      if [[ -f "$TARGET/go.sum" ]] && grep -qE '(gorm|sqlx|pgx|go-sql-driver|go.mongodb.org|bun|ent)' "$TARGET/go.sum" 2>/dev/null; then
        HAS_DATABASE=1
      fi
      ;;
    rust)
      if grep -qE '^\s*(diesel|sqlx|rusqlite|tokio-postgres|mongodb|sea-orm)\s*=' "$TARGET/Cargo.toml" 2>/dev/null; then
        HAS_DATABASE=1
      fi
      ;;
  esac
}

blue "== installing claude-sdlc-boilerplate =="
blue "target: $TARGET"
blue "mode:   $MODE  (dry-run=$DRY_RUN  force=$FORCE)"

# Populate stack globals
detect_stack
PROJECT_NAME="$(basename "$TARGET")"

blue "-- detected stack --"
printf "  project:   %s\n" "$PROJECT_NAME"
printf "  stack:     %s\n" "$STACK"
printf "  language:  %s\n" "$LANGUAGE"
printf "  framework: %s\n" "$FRAMEWORK"
printf "  pkg mgr:   %s\n" "$PKG_MGR"
printf "  test:      %s\n" "$TEST_CMD"
printf "  lint:      %s\n" "$LINT_CMD"
printf "  build:     %s\n" "$BUILD_CMD"
printf "  frontend:  %s\n" "$([[ "$HAS_FRONTEND" = "1" ]] && echo yes || echo no)"
printf "  database:  %s\n" "$([[ "$HAS_DATABASE" = "1" ]] && echo yes || echo no)"
printf "  docker:    %s\n" "$([[ "$HAS_DOCKER" = "1" ]] && echo yes || echo no)"
echo ""

# ---------- substitution helper ----------
render_template() {
  local src="$1"
  local dst="$2"
  if [[ "$DRY_RUN" = "1" ]]; then
    yellow "[dry-run] would render $src -> $dst"
    return
  fi
  sed \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{LANGUAGE}}|${LANGUAGE}|g" \
    -e "s|{{FRAMEWORK}}|${FRAMEWORK}|g" \
    -e "s|{{PKG_MGR}}|${PKG_MGR}|g" \
    -e "s|{{TEST_RUNNER}}|${TEST_RUNNER}|g" \
    -e "s|{{LINTER}}|${LINTER}|g" \
    -e "s|{{CI}}|${CI}|g" \
    -e "s|{{TEST_CMD}}|${TEST_CMD}|g" \
    -e "s|{{LINT_CMD}}|${LINT_CMD}|g" \
    -e "s|{{BUILD_CMD}}|${BUILD_CMD}|g" \
    -e "s|{{INSTALL_CMD}}|${INSTALL_CMD}|g" \
    -e "s|{{DEV_CMD}}|${DEV_CMD}|g" \
    -e "s|{{STACK}}|${STACK}|g" \
    "$src" > "$dst"
}

# ---------- CLAUDE.md ----------
action "install CLAUDE.md"
RENDERED_CLAUDE_MD="$(mktemp)"
render_template "$SCRIPT_DIR/CLAUDE.md.template" "$RENDERED_CLAUDE_MD"

if [[ ! -f "$TARGET/CLAUDE.md" ]]; then
  do_cmd "cp '$RENDERED_CLAUDE_MD' '$TARGET/CLAUDE.md'"
elif grep -q "BEGIN CLAUDE-SDLC-BOILERPLATE" "$TARGET/CLAUDE.md" 2>/dev/null; then
  action "replace existing boilerplate block in CLAUDE.md"
  if [[ "$DRY_RUN" != "1" ]]; then
    # Extract our new block from the rendered template
    NEW_BLOCK=$(awk '
      /<!-- BEGIN CLAUDE-SDLC-BOILERPLATE -->/ { inside=1 }
      inside { print }
      /<!-- END CLAUDE-SDLC-BOILERPLATE -->/   { inside=0 }
    ' "$RENDERED_CLAUDE_MD")
    # Write the existing file with the block swapped out
    python3 - "$TARGET/CLAUDE.md" <<EOF
import re, sys
path = sys.argv[1]
new_block = """$NEW_BLOCK"""
with open(path) as f:
    content = f.read()
pattern = re.compile(
    r"<!-- BEGIN CLAUDE-SDLC-BOILERPLATE -->.*?<!-- END CLAUDE-SDLC-BOILERPLATE -->",
    re.DOTALL,
)
content = pattern.sub(new_block, content)
with open(path, "w") as f:
    f.write(content)
EOF
  fi
else
  action "append boilerplate block to existing CLAUDE.md (preserving your content)"
  if [[ "$DRY_RUN" != "1" ]]; then
    # Strip the leading project-name H1 — the existing file already has its own heading.
    {
      echo ""
      awk '
        /<!-- BEGIN CLAUDE-SDLC-BOILERPLATE -->/ { found=1 }
        found { print }
      ' "$RENDERED_CLAUDE_MD"
    } >> "$TARGET/CLAUDE.md"
  fi
fi
rm -f "$RENDERED_CLAUDE_MD"

# ---------- .claude/ dirs ----------
action "create .claude/{skills,agents,hooks,logs} dirs"
do_cmd "mkdir -p '$TARGET/.claude/skills' '$TARGET/.claude/agents' '$TARGET/.claude/hooks' '$TARGET/.claude/logs'"

# ---------- settings.json ----------
RENDERED_SETTINGS="$(mktemp)"
render_template "$SCRIPT_DIR/.claude/settings.json.template" "$RENDERED_SETTINGS"

if [[ -f "$TARGET/.claude/settings.json" ]]; then
  if [[ "$FORCE" = "1" ]]; then
    action "backup existing settings.json and overwrite"
    do_cmd "cp '$TARGET/.claude/settings.json' '$TARGET/.claude/settings.json.pre-boilerplate'"
    do_cmd "cp '$RENDERED_SETTINGS' '$TARGET/.claude/settings.json'"
  else
    yellow "settings.json exists — not overwriting. Use --force to replace (existing will be backed up)."
    yellow "review $RENDERED_SETTINGS manually and merge the hooks block into your settings.json"
    if [[ "$DRY_RUN" != "1" ]]; then
      cp "$RENDERED_SETTINGS" "$TARGET/.claude/settings.json.proposed"
      yellow "wrote proposed merge to: $TARGET/.claude/settings.json.proposed"
    fi
  fi
else
  do_cmd "cp '$RENDERED_SETTINGS' '$TARGET/.claude/settings.json'"
fi
rm -f "$RENDERED_SETTINGS"

# ---------- skills, agents, hooks ----------
action "copy skills"
do_cmd "cp -R '$SCRIPT_DIR/.claude/skills/.' '$TARGET/.claude/skills/'"

action "copy always-on agents"
if [[ "$DRY_RUN" != "1" ]]; then
  find "$SCRIPT_DIR/.claude/agents" -maxdepth 1 -type f -name '*.md' \
    -exec cp {} "$TARGET/.claude/agents/" \;
fi

# Stack-gated agent installation
if [[ "$HAS_FRONTEND" = "1" ]]; then
  action "frontend detected — installing accessibility-expert + design-reviewer"
  if [[ "$DRY_RUN" != "1" ]]; then
    cp "$SCRIPT_DIR/.claude/agents/stack-gated/frontend/"*.md "$TARGET/.claude/agents/" 2>/dev/null || true
  fi
fi

if [[ "$HAS_DATABASE" = "1" ]]; then
  action "database driver detected — installing database-expert"
  if [[ "$DRY_RUN" != "1" ]]; then
    cp "$SCRIPT_DIR/.claude/agents/stack-gated/database/"*.md "$TARGET/.claude/agents/" 2>/dev/null || true
  fi
fi

if [[ "$HAS_DOCKER" = "1" ]]; then
  action "Dockerfile detected — installing docker-expert"
  if [[ "$DRY_RUN" != "1" ]]; then
    cp "$SCRIPT_DIR/.claude/agents/stack-gated/docker/"*.md "$TARGET/.claude/agents/" 2>/dev/null || true
  fi
fi

action "copy hooks"
do_cmd "cp -R '$SCRIPT_DIR/.claude/hooks/.' '$TARGET/.claude/hooks/'"

action "make hooks and scripts executable"
if [[ "$DRY_RUN" != "1" ]]; then
  find "$TARGET/.claude/hooks" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
  find "$TARGET/.claude/skills" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
fi

# ---------- memory-bank ----------
action "install memory-bank files"
if [[ "$DRY_RUN" != "1" ]]; then
  for f in CLAUDE-activeContext.md CLAUDE-patterns.md CLAUDE-decisions.md CLAUDE-troubleshooting.md; do
    src="$SCRIPT_DIR/memory-bank-templates/$f"
    dst="$TARGET/$f"
    if [[ ! -f "$dst" ]]; then
      render_template "$src" "$dst"
    fi
  done
  mkdir -p "$TARGET/.claude/memory-bank"
fi

# ---------- .gitignore ----------
action "ensure .claude/logs/ and per-branch memory-bank state are gitignored"
if [[ "$DRY_RUN" != "1" ]]; then
  GI="$TARGET/.gitignore"
  touch "$GI"
  for line in ".claude/logs/" ".claude/settings.local.json" ".claude/settings.json.proposed" ".claude/settings.json.pre-boilerplate" ".claude/memory-bank/"; do
    grep -qxF "$line" "$GI" || echo "$line" >> "$GI"
  done
fi

green ""
green "✓ claude-sdlc-boilerplate installed into $TARGET"
green ""
green "installed:"
green "  • $(ls "$TARGET/.claude/skills" 2>/dev/null | wc -l) skills in .claude/skills/"
green "  • $(ls "$TARGET/.claude/agents" 2>/dev/null | grep -c '\.md$') agents in .claude/agents/"
green "  • $(ls "$TARGET/.claude/hooks" 2>/dev/null | wc -l) hooks in .claude/hooks/"
green "  • memory-bank files: CLAUDE-activeContext.md, -patterns.md, -decisions.md, -troubleshooting.md"
green ""
green "next steps:"
green "  1. open $TARGET/CLAUDE.md and fill in the TODOs (architecture, folder layout, gotchas)"
green "  2. scan the memory-bank files at the repo root and seed them with what you know"
green "  3. review $TARGET/.claude/settings.json permissions — tighten for your project"
green "  4. read $TARGET/.claude/skills/feature-implementation/references/ and customize"
green "  5. try a skill: open Claude Code in $TARGET and type '/code-review' or '/spec:create my-feature'"
green ""
green "to uninstall: $0 --uninstall $TARGET"
