#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# publish.sh — Push clean framework to public distribution repo
#
# Usage:
#   ./scripts/publish.sh                  # publish current state
#   ./scripts/publish.sh --tag v4.0.0     # publish and tag a release
#   ./scripts/publish.sh --dry-run        # show what would be copied
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="/tmp/mythic-os-dist"
DIST_REPO="Unveiled8300/mythic-os"

# Parse args
TAG=""
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --tag) shift; TAG="${1:-}"; shift || true ;;
    --tag=*) TAG="${arg#--tag=}" ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

echo "Source: $SOURCE_DIR"
echo "Dist:   $DIST_DIR"
echo "Repo:   $DIST_REPO"
[ -n "$TAG" ] && echo "Tag:    $TAG"
echo ""

# ── Step 1: Clean dist directory ──────────────────────────────
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ── Step 2: Copy framework files (whitelist approach) ─────────
# Only copy what belongs in the distribution. Everything else stays local.

# Core files
cp "$SOURCE_DIR/CLAUDE.md" "$DIST_DIR/"
cp "$SOURCE_DIR/LIBRARY.md" "$DIST_DIR/"
cp "$SOURCE_DIR/settings.json" "$DIST_DIR/"
cp "$SOURCE_DIR/README.md" "$DIST_DIR/" 2>/dev/null || true
cp "$SOURCE_DIR/install.sh" "$DIST_DIR/" 2>/dev/null || true
cp "$SOURCE_DIR/.gitignore" "$DIST_DIR/"

# Rules (role contracts)
if [ -d "$SOURCE_DIR/rules" ]; then
  cp -r "$SOURCE_DIR/rules" "$DIST_DIR/rules"
fi

# Skills (slash commands)
if [ -d "$SOURCE_DIR/skills" ]; then
  mkdir -p "$DIST_DIR/skills"
  # Copy skill definitions but exclude any .claude/ session dirs
  rsync -a --exclude='.claude/' "$SOURCE_DIR/skills/" "$DIST_DIR/skills/"
fi

# Hooks (enforcement + context-loader)
if [ -d "$SOURCE_DIR/hooks" ]; then
  cp -r "$SOURCE_DIR/hooks" "$DIST_DIR/hooks"
fi

# Stacks (project templates)
if [ -d "$SOURCE_DIR/stacks" ]; then
  cp -r "$SOURCE_DIR/stacks" "$DIST_DIR/stacks"
fi

# Templates
if [ -d "$SOURCE_DIR/templates" ]; then
  cp -r "$SOURCE_DIR/templates" "$DIST_DIR/templates"
fi

# Agents
if [ -d "$SOURCE_DIR/agents" ]; then
  cp -r "$SOURCE_DIR/agents" "$DIST_DIR/agents"
fi

# Commands
if [ -d "$SOURCE_DIR/commands" ]; then
  cp -r "$SOURCE_DIR/commands" "$DIST_DIR/commands"
fi

# Scripts (including this publish script)
mkdir -p "$DIST_DIR/scripts"
cp "$SOURCE_DIR/scripts/publish.sh" "$DIST_DIR/scripts/"

# Brain — only the empty scaffold, never accumulated data
mkdir -p "$DIST_DIR/brain/log/errors"
mkdir -p "$DIST_DIR/brain/log/decisions"
mkdir -p "$DIST_DIR/brain/log/fixes"
mkdir -p "$DIST_DIR/brain/patterns"
mkdir -p "$DIST_DIR/brain/playbooks"
cp "$SOURCE_DIR/brain/index.md" "$DIST_DIR/brain/index.md"

# Error-records — empty scaffold only
mkdir -p "$DIST_DIR/error-records"
touch "$DIST_DIR/error-records/.gitkeep"

# ADR — empty scaffold only
mkdir -p "$DIST_DIR/adr"
touch "$DIST_DIR/adr/.gitkeep"

# ── Step 3: Strip personal data ───────────────────────────────
# Remove any accumulated brain data that might have slipped through
rm -f "$DIST_DIR"/brain/log/errors/*.md 2>/dev/null || true
rm -f "$DIST_DIR"/brain/log/decisions/*.md 2>/dev/null || true
rm -f "$DIST_DIR"/brain/log/fixes/*.md 2>/dev/null || true
rm -f "$DIST_DIR"/brain/patterns/*.md 2>/dev/null || true
rm -f "$DIST_DIR"/brain/playbooks/*.md 2>/dev/null || true
rm -f "$DIST_DIR"/brain/log/fragment-usage.jsonl 2>/dev/null || true
rm -f "$DIST_DIR"/error-records/*.md 2>/dev/null || true

# Remove experiment runtime data (results, reports, configs from past runs)
find "$DIST_DIR" -name "results.tsv" -delete 2>/dev/null || true
find "$DIST_DIR" -name "final_artifact.md" -path "*/experiments/*" -delete 2>/dev/null || true
find "$DIST_DIR" -name "report.md" -path "*/experiments/*" -delete 2>/dev/null || true
find "$DIST_DIR" -name "patterns.md" -path "*/experiments/*" -delete 2>/dev/null || true
rm -rf "$DIST_DIR"/skills/self-iterate/experiments 2>/dev/null || true
rm -f "$DIST_DIR"/skills/self-iterate/config.yaml 2>/dev/null || true

# Remove any project-specific files
rm -f "$DIST_DIR"/SPRINT.md "$DIST_DIR"/SPEC.md "$DIST_DIR"/HANDOFF.md 2>/dev/null || true
rm -f "$DIST_DIR"/GOVERNANCE-SPRINT.md "$DIST_DIR"/mvp_prd.md 2>/dev/null || true
rm -f "$DIST_DIR"/LIBRARY-HISTORY.md 2>/dev/null || true

# Remove projects directory if it slipped in
rm -rf "$DIST_DIR"/projects-mythic 2>/dev/null || true

# ── Step 4: Scrub for secrets ─────────────────────────────────
# Final safety scan — exclude files that legitimately contain secret patterns
# (enforcement hooks, CI templates, and this script contain regex patterns, not real secrets)
SECRETS_FOUND=$(grep -rE 'sk_live_[A-Za-z0-9]{10,}|sk_test_[A-Za-z0-9]{10,}|AKIA[0-9A-Z]{16}[A-Za-z0-9]+|ghp_[A-Za-z0-9]{36}|-----BEGIN (RSA |EC )?PRIVATE KEY-----' \
  --include='*.md' --include='*.json' --include='*.yaml' --include='*.yml' \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.py' \
  --exclude-dir='.git' \
  "$DIST_DIR" 2>/dev/null | \
  grep -v 'secret.scan\.py' | \
  grep -v 'catastrophic.gate\.py' | \
  grep -v 'pre-commit' | \
  grep -v 'ci\.yml' | \
  grep -v 'publish\.sh' | \
  grep -v 'sk_live_\.\.\.' | \
  grep -v 'sk_test_\.\.\.' || true)
if [ -n "$SECRETS_FOUND" ]; then
  echo ""
  echo "!! SECRET DETECTED IN DIST — ABORTING !!"
  echo "$SECRETS_FOUND"
  echo ""
  echo "Fix the source file before publishing."
  rm -rf "$DIST_DIR"
  exit 1
fi

# ── Step 5: Report what's included ────────────────────────────
echo "Distribution contents:"
echo ""
find "$DIST_DIR" -type f | sed "s|$DIST_DIR/||" | sort | head -80
TOTAL=$(find "$DIST_DIR" -type f | wc -l | tr -d ' ')
echo ""
echo "Total files: $TOTAL"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN — no changes pushed. Distribution at: $DIST_DIR"
  exit 0
fi

# ── Step 6: Push to public repo ───────────────────────────────
echo "Checking if dist repo exists..."

# Clone or pull the dist repo
REPO_DIR="/tmp/mythic-os-repo"
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  git fetch origin 2>/dev/null || true
  git checkout main 2>/dev/null || git checkout -b main
  git reset --hard origin/main 2>/dev/null || true
else
  rm -rf "$REPO_DIR"
  if gh repo view "$DIST_REPO" &>/dev/null; then
    git clone "https://github.com/$DIST_REPO.git" "$REPO_DIR"
    cd "$REPO_DIR"
  else
    echo "Public repo $DIST_REPO does not exist yet."
    echo "Create it first: gh repo create $DIST_REPO --public --description 'Mythic OS — Claude Code governance framework'"
    echo "Then run this script again."
    exit 1
  fi
fi

# Sync: delete everything in repo, copy fresh from dist
cd "$REPO_DIR"
git rm -rf . --quiet 2>/dev/null || true
cp -r "$DIST_DIR"/* "$REPO_DIR/"
cp "$DIST_DIR/.gitignore" "$REPO_DIR/.gitignore"

# Stage everything
git add -A

# Check if there are changes
if git diff --cached --quiet; then
  echo "No changes to publish."
  exit 0
fi

# Commit
if [ -n "$TAG" ]; then
  git commit -m "release: $TAG"
  git tag -a "$TAG" -m "Release $TAG"
  echo ""
  echo "Tagged: $TAG"
else
  git commit -m "chore: sync framework from development"
fi

# Push
git push origin main
[ -n "$TAG" ] && git push origin "$TAG"

echo ""
echo "Published to https://github.com/$DIST_REPO"
[ -n "$TAG" ] && echo "Release: $TAG"
echo ""

# Cleanup
rm -rf "$DIST_DIR"
