# gstack Native Plugin Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert gstack from a custom-installed 43-skill collection into a native Claude Code plugin, eliminating all custom install infrastructure while preserving skill methodologies and the browse daemon.

**Architecture:** New plugin shell (`.claude-plugin/plugin.json`) with skills migrated in 8 phases. Kept bin scripts rewritten to use `.claude/gstack/` project-local state. Browse daemon stays at `browse/dist/browse` with a `bin/` wrapper. Upstream sync via tracking branch + diff script.

**Tech Stack:** Bash (bin scripts), Bun (browse daemon build), Claude Code plugin format (plugin.json, SKILL.md, hooks.json)

**Spec:** `docs/superpowers/specs/2026-04-29-gstack-native-plugin-migration-design.md`

---

## Task 1: Plugin Scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `hooks/hooks.json`
- Create: `skills/_context/SKILL.md`
- Create: `skills/_test/SKILL.md`
- Create: `bin/gstack-test-path`
- Create: `MIGRATION.md`

- [ ] **Step 1: Create plugin manifest**

```bash
mkdir -p .claude-plugin
```

Write `.claude-plugin/plugin.json`:
```json
{
  "name": "gstack",
  "description": "Virtual engineering team — 43 specialist skills for review, QA, planning, design, shipping, and browser automation",
  "version": "1.0.0",
  "author": {
    "name": "Peter Yu (forked from Garry Tan)"
  },
  "repository": "https://github.com/alandy88/gstack"
}
```

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p skills/_context skills/_test hooks bin/migrated scripts
```

- [ ] **Step 3: Create SessionStart hook**

Write `hooks/hooks.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .claude/gstack && touch .claude/gstack/learnings.jsonl",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 4: Create shared context skill**

Write `skills/_context/SKILL.md`:
```markdown
---
name: _context
description: Project context and learnings for gstack skills. Loads project-specific learnings and provides context for all other gstack skills.
user-invocable: false
---

## Project Learnings

When starting work, check `.claude/gstack/learnings.jsonl` for prior
learnings in this project. Apply relevant ones silently.

When completing work that produced a reusable insight, append to
learnings.jsonl using `gstack-learnings-log`:

```bash
gstack-learnings-log '{"skill":"<name>","type":"<pattern|pitfall|preference|architecture|tool|operational>","key":"<kebab-case>","insight":"<description>","confidence":N,"source":"<observed|user-stated|inferred>"}'
```

## Project Context

Check recent git history and README for project awareness before
executing skill-specific methodology.
```

- [ ] **Step 5: Create test skill for spike validation**

Write `skills/_test/SKILL.md`:
```markdown
---
name: _test
description: Smoke test for gstack plugin scaffold. Validates plugin loading, skill invocation, bin/ PATH injection, and SessionStart hook.
disable-model-invocation: true
---

# Plugin Scaffold Smoke Test

Verify all plugin components work:

1. **Plugin loaded:** You are reading this, so the plugin loaded correctly.

2. **bin/ PATH:** Run this command to verify bin/ is on PATH:
```bash
gstack-test-path
```
Expected output: `gstack-test-path: OK`

3. **SessionStart hook:** Check that `.claude/gstack/learnings.jsonl` exists:
```bash
ls -la .claude/gstack/learnings.jsonl
```

4. **Shared context skill:** Verify _context skill is discoverable:
Ask "What skills are available?" and confirm _context appears.

Report results.
```

- [ ] **Step 6: Create test bin script**

Write `bin/gstack-test-path`:
```bash
#!/usr/bin/env bash
echo "gstack-test-path: OK"
```

```bash
chmod +x bin/gstack-test-path
```

- [ ] **Step 7: Create migration tracking manifest**

Write `MIGRATION.md`:
```markdown
# gstack Migration Tracker

## Phase 0A: Plugin Scaffold
- [x] plugin.json
- [x] hooks/hooks.json
- [x] skills/_context/SKILL.md
- [x] skills/_test/SKILL.md
- [x] bin/ PATH validation

## Phase 0B: Shared Runtime
- [ ] gstack-slug
- [ ] gstack-learnings-log
- [ ] gstack-learnings-search
- [ ] gstack-diff-scope
- [ ] gstack-review-log
- [ ] gstack-review-read
- [ ] gstack-next-version
- [ ] gstack-taste-update
- [ ] upstream remote + mirror branch
- [ ] scripts/upstream-diff.sh

## Phase 1: Simple Standalone Skills
- [ ] careful
- [ ] freeze
- [ ] guard
- [ ] unfreeze
- [ ] learn
- [ ] investigate

## Phase 2: Review & Planning Skills
- [ ] review
- [ ] cso
- [ ] plan-ceo-review
- [ ] plan-eng-review
- [ ] plan-design-review
- [ ] plan-devex-review
- [ ] office-hours
- [ ] retro
- [ ] autoplan

## Phase 3: Ship & Deploy Skills
- [ ] ship
- [ ] land-and-deploy
- [ ] canary
- [ ] document-release
- [ ] benchmark
- [ ] benchmark-models

## Phase 4: Design Skills
- [ ] design-review
- [ ] design-consultation
- [ ] design-html
- [ ] design-shotgun
- [ ] devex-review

## Phase 5: Browser Skills
- [ ] browse daemon in bin/
- [ ] browse
- [ ] qa
- [ ] qa-only
- [ ] open-gstack-browser

## Phase 6: Infrastructure & Cleanup
- [ ] setup-deploy
- [ ] setup-browser-cookies
- [ ] plan-tune
- [ ] health (rewrite)
- [ ] landing-report (evaluate)
- [ ] Drop: context-save, context-restore, gstack-upgrade, codex, setup-gbrain, make-pdf, openclaw, claude, contrib

## Post-Migration
- [ ] Delete root-level skill dirs
- [ ] Delete setup, hosts/, template pipeline
- [ ] Delete extension/, supabase/, design/dist/, make-pdf/dist/
- [ ] Update README.md
```

- [ ] **Step 8: Validate plugin loads**

Run: `claude --plugin-dir .`
Then: `/gstack:_test`

Expected: plugin loads, test skill invokes, bin/ PATH works, hook creates `.claude/gstack/`.

- [ ] **Step 9: Commit**

```bash
git add .claude-plugin/ skills/_context/ skills/_test/ hooks/ bin/gstack-test-path MIGRATION.md
git commit -m "feat: plugin scaffold with manifest, hooks, context skill, and spike test"
```

---

## Task 2: Shared Runtime Scripts

**Files:**
- Copy+modify: `bin/gstack-slug` (from current `bin/gstack-slug`)
- Copy+modify: `bin/gstack-learnings-log` (from current `bin/gstack-learnings-log`)
- Copy+modify: `bin/gstack-learnings-search` (from current `bin/gstack-learnings-search`)
- Copy: `bin/gstack-diff-scope` (from current `bin/gstack-diff-scope`)
- Copy+modify: `bin/gstack-review-log` (from current `bin/gstack-review-log`)
- Copy+modify: `bin/gstack-review-read` (from current `bin/gstack-review-read`)
- Copy: `bin/gstack-next-version` (from current `bin/gstack-next-version`)
- Copy: `bin/gstack-taste-update` (from current `bin/gstack-taste-update`)

All "copy+modify" scripts need path rewriting: `$HOME/.gstack/projects/$SLUG/` → `.claude/gstack/`

- [ ] **Step 1: Copy and patch gstack-slug**

Copy `bin/gstack-slug` to `bin/migrated/gstack-slug`.

Patch: change the cache dir from `$HOME/.gstack/slug-cache` to `.claude/gstack/slug-cache`. The script itself doesn't depend on any other gstack scripts, so it works standalone.

Edit the copied file — change line:
```bash
CACHE_DIR="$HOME/.gstack/slug-cache"
```
to:
```bash
CACHE_DIR=".claude/gstack/slug-cache"
```

```bash
chmod +x bin/migrated/gstack-slug
```

- [ ] **Step 2: Copy and patch gstack-learnings-log**

Copy `bin/gstack-learnings-log` to `bin/migrated/gstack-learnings-log`.

Three changes needed:

a) Change GSTACK_HOME default and mkdir target:
```bash
# OLD:
GSTACK_HOME="${GSTACK_HOME:-$HOME/.gstack}"
mkdir -p "$GSTACK_HOME/projects/$SLUG"
# NEW:
GSTACK_HOME="${GSTACK_HOME:-.claude/gstack}"
mkdir -p "$GSTACK_HOME"
```

b) Change the learnings file path:
```bash
# OLD:
echo "$VALIDATED" >> "$GSTACK_HOME/projects/$SLUG/learnings.jsonl"
# NEW:
echo "$VALIDATED" >> "$GSTACK_HOME/learnings.jsonl"
```

c) Remove the gbrain-sync line at the end:
```bash
# DELETE this line:
"$SCRIPT_DIR/gstack-brain-enqueue" "projects/$SLUG/learnings.jsonl" 2>/dev/null &
```

d) Update SCRIPT_DIR slug call to use migrated version:
```bash
# The existing line works as-is because it uses $SCRIPT_DIR/gstack-slug
# which resolves to the same bin/ directory
```

```bash
chmod +x bin/migrated/gstack-learnings-log
```

- [ ] **Step 3: Copy and patch gstack-learnings-search**

Copy `bin/gstack-learnings-search` to `bin/migrated/gstack-learnings-search`.

Changes:

a) Change GSTACK_HOME and learnings file path:
```bash
# OLD:
GSTACK_HOME="${GSTACK_HOME:-$HOME/.gstack}"
# ...
LEARNINGS_FILE="$GSTACK_HOME/projects/$SLUG/learnings.jsonl"
# NEW:
GSTACK_HOME="${GSTACK_HOME:-.claude/gstack}"
# ...
LEARNINGS_FILE="$GSTACK_HOME/learnings.jsonl"
```

b) Remove cross-project search (searches `$GSTACK_HOME/projects` which no longer exists):
```bash
# DELETE the cross-project find block:
if [ "$CROSS_PROJECT" = true ]; then
  for f in $(find "$GSTACK_HOME/projects" -name "learnings.jsonl" -not -path "*/$SLUG/*" 2>/dev/null | head -5); do
    FILES+=("$f")
  done
fi
```

```bash
chmod +x bin/migrated/gstack-learnings-search
```

- [ ] **Step 4: Copy and patch gstack-review-log**

Copy `bin/gstack-review-log` to `bin/migrated/gstack-review-log`.

Changes:

a) Change GSTACK_HOME and path:
```bash
# OLD:
GSTACK_HOME="${GSTACK_HOME:-$HOME/.gstack}"
mkdir -p "$GSTACK_HOME/projects/$SLUG"
# ...
echo "$INPUT" >> "$GSTACK_HOME/projects/$SLUG/$BRANCH-reviews.jsonl"
# NEW:
GSTACK_HOME="${GSTACK_HOME:-.claude/gstack}"
mkdir -p "$GSTACK_HOME/reviews"
# ...
echo "$INPUT" >> "$GSTACK_HOME/reviews/$BRANCH-reviews.jsonl"
```

b) Remove gbrain-sync line:
```bash
# DELETE:
"$SCRIPT_DIR/gstack-brain-enqueue" "projects/$SLUG/$BRANCH-reviews.jsonl" 2>/dev/null &
```

c) Remove bun JSON validation (replace with simpler check or keep if bun is available):
Keep the bun validation as-is — it's a reasonable dependency since browse daemon requires bun anyway.

```bash
chmod +x bin/migrated/gstack-review-log
```

- [ ] **Step 5: Copy and patch gstack-review-read**

Copy `bin/gstack-review-read` to `bin/migrated/gstack-review-read`.

Changes:

a) Change GSTACK_HOME and path:
```bash
# OLD:
GSTACK_HOME="${GSTACK_HOME:-$HOME/.gstack}"
cat "$GSTACK_HOME/projects/$SLUG/$BRANCH-reviews.jsonl" 2>/dev/null || echo "NO_REVIEWS"
# NEW:
GSTACK_HOME="${GSTACK_HOME:-.claude/gstack}"
cat "$GSTACK_HOME/reviews/$BRANCH-reviews.jsonl" 2>/dev/null || echo "NO_REVIEWS"
```

b) Remove gstack-config call:
```bash
# OLD:
"$SCRIPT_DIR/gstack-config" get skip_eng_review 2>/dev/null || echo "false"
# NEW:
echo "false"
```

```bash
chmod +x bin/migrated/gstack-review-read
```

- [ ] **Step 6: Copy gstack-diff-scope as-is**

Copy `bin/gstack-diff-scope` to `bin/migrated/gstack-diff-scope`. No changes needed — it only reads git state, no gstack paths.

```bash
cp bin/gstack-diff-scope bin/migrated/gstack-diff-scope
chmod +x bin/migrated/gstack-diff-scope
```

- [ ] **Step 7: Copy gstack-next-version and gstack-taste-update**

These are larger scripts. Copy to `bin/migrated/` and audit for `~/.gstack/` paths:

```bash
cp bin/gstack-next-version bin/migrated/gstack-next-version
cp bin/gstack-taste-update bin/migrated/gstack-taste-update
chmod +x bin/migrated/gstack-next-version bin/migrated/gstack-taste-update
```

For each, search and replace:
- `$HOME/.gstack` → `.claude/gstack`
- Remove any `gstack-brain-enqueue` calls
- Remove any `gstack-config` calls (replace with defaults)

- [ ] **Step 8: Move migrated scripts to bin/ root**

Once all scripts are patched and tested:

```bash
# Replace originals with migrated versions
for f in bin/migrated/*; do
  cp "$f" "bin/$(basename $f)"
done
rm -rf bin/migrated
```

- [ ] **Step 9: Verify scripts work**

```bash
# Test gstack-slug
eval "$(bin/gstack-slug)"
echo "SLUG=$SLUG BRANCH=$BRANCH"

# Test gstack-learnings-log (creates .claude/gstack/ structure)
mkdir -p .claude/gstack
bin/gstack-learnings-log '{"skill":"test","type":"pattern","key":"test-key","insight":"test insight","confidence":5,"source":"observed"}'
cat .claude/gstack/learnings.jsonl

# Test gstack-learnings-search
bin/gstack-learnings-search --limit 5

# Test gstack-diff-scope
source <(bin/gstack-diff-scope main)
echo "SCOPE_FRONTEND=$SCOPE_FRONTEND"
```

Expected: all commands succeed, learnings.jsonl has an entry, diff-scope outputs scope vars.

- [ ] **Step 10: Commit**

```bash
git add bin/gstack-slug bin/gstack-learnings-log bin/gstack-learnings-search bin/gstack-diff-scope bin/gstack-review-log bin/gstack-review-read bin/gstack-next-version bin/gstack-taste-update
git commit -m "feat: migrate shared runtime scripts with project-local state paths"
```

---

## Task 3: Upstream Sync Setup

**Files:**
- Create: `scripts/upstream-diff.sh`
- Modify: `CLAUDE.md` (plugin-level)

- [ ] **Step 1: Add upstream remote**

```bash
git remote add upstream https://github.com/garrytan/gstack.git
git fetch upstream
```

- [ ] **Step 2: Create upstream-mirror branch**

```bash
git checkout -b upstream-mirror upstream/master
git checkout main
```

- [ ] **Step 3: Create diff script**

Write `scripts/upstream-diff.sh`:
```bash
#!/usr/bin/env bash
# Compare upstream SKILL.md methodology content vs migrated skills.
# Strips preamble (everything from "## Preamble" to closing ```) and
# host-specific sections before diffing.
set -euo pipefail

UPSTREAM_BRANCH="${1:-upstream-mirror}"
PLUGIN_SKILLS="skills"
CHANGES=0
NEW=0

echo "=== gstack upstream diff ==="
echo "Comparing against: $UPSTREAM_BRANCH"
echo ""

# Check migrated skills for upstream changes
for skill_dir in "$PLUGIN_SKILLS"/*/; do
    skill=$(basename "$skill_dir")
    [[ "$skill" == _* ]] && continue  # skip internal skills

    # Try multiple upstream locations
    upstream_file=""
    for candidate in "$skill/SKILL.md"; do
        if git show "$UPSTREAM_BRANCH:$candidate" &>/dev/null; then
            upstream_file="$candidate"
            break
        fi
    done
    [ -z "$upstream_file" ] && continue

    # Strip preamble and auto-generated markers from upstream
    upstream_content=$(git show "$UPSTREAM_BRANCH:$upstream_file" 2>/dev/null \
        | sed '/^---$/,/^---$/d' \
        | sed '/<!-- AUTO-GENERATED/d' \
        | sed '/<!-- Regenerate:/d' \
        | sed '/^## Preamble/,/^```$/d' \
        | sed '/^## Plan Mode Safe Operations/,/^## [^P]/{ /^## [^P]/!d; }' \
        | sed '/^## Skill Invocation During/,/^## [^S]/{ /^## [^S]/!d; }')

    # Strip frontmatter from local
    local_content=$(sed '/^---$/,/^---$/d' "$skill_dir/SKILL.md" 2>/dev/null)

    diff_output=$(diff <(echo "$upstream_content") <(echo "$local_content") 2>/dev/null) || true
    if [ -n "$diff_output" ]; then
        echo "CHANGED: $skill"
        echo "$diff_output" | head -30
        echo ""
        CHANGES=$((CHANGES + 1))
    fi
done

# Check for new upstream skills not yet migrated
for upstream_dir in $(git ls-tree -d --name-only "$UPSTREAM_BRANCH" 2>/dev/null); do
    if git show "$UPSTREAM_BRANCH:$upstream_dir/SKILL.md" &>/dev/null; then
        if [ ! -d "$PLUGIN_SKILLS/$upstream_dir" ]; then
            echo "NEW UPSTREAM: $upstream_dir (not migrated)"
            NEW=$((NEW + 1))
        fi
    fi
done

echo ""
echo "=== Summary: $CHANGES changed, $NEW new upstream skills ==="
```

```bash
chmod +x scripts/upstream-diff.sh
```

- [ ] **Step 4: Write plugin CLAUDE.md**

Write `CLAUDE.md` (at repo root — replace existing gstack CLAUDE.md):

```markdown
# gstack — Native Claude Code Plugin

Forked from [garrytan/gstack](https://github.com/garrytan/gstack) and converted to native Claude Code plugin format.

## Development

Load plugin for testing:
```bash
claude --plugin-dir /d/Git/gstack
```

Reload after changes: `/reload-plugins`

## Upstream Sync

```bash
git fetch upstream
git checkout upstream-mirror && git merge upstream/master && git checkout main
scripts/upstream-diff.sh
```

## Browse Daemon

Build: `cd browse && bun run build`
Binary: `browse/dist/browse`
State: `.gstack/browse.json` (project-local)

## State

Project-local: `.claude/gstack/` (learnings, reviews, plans, taste profile)
Browse state: `.gstack/` (daemon PID, port, logs)
Global: `~/.gstack/models/` (ONNX cache), `~/.gstack/security/` (attempt log)

## Bin Scripts

Kept scripts in `bin/` use `.claude/gstack/` for state (not `~/.gstack/projects/`).
```

- [ ] **Step 5: Commit**

```bash
git add scripts/upstream-diff.sh CLAUDE.md
git commit -m "feat: upstream sync setup with diff script and plugin CLAUDE.md"
```

---

## Task 4: Phase 1 — Simple Standalone Skills

**Files:**
- Create: `skills/careful/SKILL.md`, `skills/careful/bin/check-careful.sh`
- Create: `skills/freeze/SKILL.md`, `skills/freeze/bin/check-freeze.sh`
- Create: `skills/guard/SKILL.md`
- Create: `skills/unfreeze/SKILL.md`
- Create: `skills/learn/SKILL.md`
- Create: `skills/investigate/SKILL.md`
- Modify: `MIGRATION.md`

These skills are small (44-918 lines) and have minimal preamble. The stripping pattern for each:
1. Keep YAML frontmatter (remove `preamble-tier`, `version`, `triggers` fields — not native plugin fields)
2. Delete `<!-- AUTO-GENERATED -->` comments
3. Delete `## Preamble (run first)` section through closing ``` of bash block
4. Delete any `~/.gstack/analytics` telemetry lines (inline bash blocks)
5. Delete host-specific sections (Codex/Cursor/Factory mentions)
6. Keep `hooks` field in frontmatter if present (careful, freeze use PreToolUse hooks)
7. Update `(gstack)` suffix in description — remove it (plugin namespace handles this)

- [ ] **Step 1: Migrate careful**

Copy `careful/SKILL.md` to `skills/careful/SKILL.md`.
Copy `careful/bin/check-careful.sh` to `skills/careful/bin/check-careful.sh`.

Edit `skills/careful/SKILL.md`:
- Remove `version: 0.1.0` from frontmatter
- Remove `triggers:` block from frontmatter
- Remove `(gstack)` from description
- Delete `<!-- AUTO-GENERATED -->` and `<!-- Regenerate -->` comment lines
- Delete the inline analytics bash block (lines ~32-35 that write to `~/.gstack/analytics/skill-usage.jsonl`)
- Update hook command path: `bash ${CLAUDE_SKILL_DIR}/bin/check-careful.sh` (already uses `${CLAUDE_SKILL_DIR}` — no change needed)

```bash
chmod +x skills/careful/bin/check-careful.sh
```

- [ ] **Step 2: Migrate freeze**

Same pattern as careful. Copy `freeze/SKILL.md` → `skills/freeze/SKILL.md`, `freeze/bin/check-freeze.sh` → `skills/freeze/bin/check-freeze.sh`.

Strip: `version`, `triggers`, `(gstack)`, auto-generated comments, analytics block.

- [ ] **Step 3: Migrate guard**

Copy `guard/SKILL.md` → `skills/guard/SKILL.md`. No supporting files.

Strip: `version`, `triggers`, `(gstack)`, auto-generated comments, analytics block.

- [ ] **Step 4: Migrate unfreeze**

Copy `unfreeze/SKILL.md` → `skills/unfreeze/SKILL.md`. No supporting files.

Strip same fields.

- [ ] **Step 5: Migrate learn**

Copy `learn/SKILL.md` → `skills/learn/SKILL.md`.

This skill is larger (836 lines) and has a full preamble. Strip:
- Frontmatter: remove `version`, `preamble-tier`, `triggers`
- Delete `## Preamble (run first)` through closing ``` (~80 lines)
- Delete any `gstack-timeline-log`, `gstack-telemetry-log`, `gstack-question-log`, `gstack-question-preference`, `gstack-brain-*`, `gstack-config` calls
- Rewrite `~/.gstack/projects/$SLUG/learnings.jsonl` → `.claude/gstack/learnings.jsonl`
- Rewrite `gstack-learnings-log` and `gstack-learnings-search` calls to not include path prefix (they're on PATH via bin/)
- Delete host-specific sections mentioning Codex, Cursor, Factory, etc.
- Delete vendoring warning section
- Delete telemetry/proactive consent sections
- Delete GBrain sync sections

- [ ] **Step 6: Migrate investigate**

Copy `investigate/SKILL.md` → `skills/investigate/SKILL.md`.

Same stripping pattern as learn (918 lines, full preamble).

- [ ] **Step 7: Validate all Phase 1 skills load**

```bash
claude --plugin-dir .
```

Then try:
- `/gstack:careful`
- `/gstack:freeze`
- `/gstack:learn`

Verify each loads and shows its methodology content (not preamble infrastructure).

- [ ] **Step 8: Update MIGRATION.md and commit**

Mark Phase 1 skills as done in `MIGRATION.md`.

```bash
git add skills/careful/ skills/freeze/ skills/guard/ skills/unfreeze/ skills/learn/ skills/investigate/ MIGRATION.md
git commit -m "feat: migrate Phase 1 skills (careful, freeze, guard, unfreeze, learn, investigate)"
```

---

## Task 5: Phase 2 — Review & Planning Skills

**Files:**
- Create: `skills/review/SKILL.md`
- Create: `skills/cso/SKILL.md`
- Create: `skills/plan-ceo-review/SKILL.md`
- Create: `skills/plan-eng-review/SKILL.md`
- Create: `skills/plan-design-review/SKILL.md`
- Create: `skills/plan-devex-review/SKILL.md`
- Create: `skills/office-hours/SKILL.md`
- Create: `skills/retro/SKILL.md`
- Create: `skills/autoplan/SKILL.md`
- Modify: `MIGRATION.md`

These are the largest skills (1,100-2,000+ lines each). Same stripping pattern but more content to audit. Key differences from Phase 1:

- `review` and `cso` use `gstack-diff-scope`, `gstack-review-log`, `gstack-review-read` — these are kept bin scripts, so calls stay but verify they reference no paths
- `review` uses `gstack-specialist-stats` — evaluate whether to keep or drop
- `autoplan` references other plan skills by name — update references from `/plan-ceo-review` to `/gstack:plan-ceo-review`
- All use `gstack-learnings-search` and `gstack-learnings-log` — calls stay, path rewrites needed

- [ ] **Step 1: Migrate review**

Copy `review/SKILL.md` → `skills/review/SKILL.md`.

This is the template for all complex skill migrations. Full stripping:

a) Frontmatter: keep `name`, `description`, `allowed-tools`. Remove `preamble-tier`, `version`, `triggers`. Remove `(gstack)` from description.

b) Delete everything between `## Preamble (run first)` and the next `##` heading after the closing ``` (lines ~29-107 in current file). This removes the entire preamble bash block.

c) Delete `## Plan Mode Safe Operations` section (gstack-specific).

d) Delete `## Skill Invocation During Plan Mode` section (gstack-specific).

e) Search for remaining `gstack-` calls throughout the file:
   - `gstack-diff-scope` → keep (on bin/ PATH)
   - `gstack-review-log` → keep
   - `gstack-review-read` → keep
   - `gstack-learnings-log` → keep
   - `gstack-learnings-search` → keep
   - `gstack-specialist-stats` → keep if present, evaluate later
   - `gstack-timeline-log` → delete the line/block
   - `gstack-telemetry-log` → delete
   - `gstack-question-log` → delete
   - `gstack-question-preference` → delete
   - `gstack-brain-*` → delete
   - `gstack-config` → delete (replace with hardcoded defaults)
   - `gstack-next-version` → keep if present

f) Rewrite path references:
   - `~/.gstack/projects/$SLUG/` → `.claude/gstack/`
   - `~/.claude/skills/gstack/bin/` → just command name (on PATH)

g) Delete sections mentioning: Codex, Factory, OpenCode, Cursor, Kiro, Hermes, GBrain, OpenClaw.

h) Delete sections about: vendoring warnings, telemetry consent, proactive consent, lake principle, writing style prompt, continuous checkpoint feature discovery.

- [ ] **Step 2: Migrate cso**

Same pattern as review. CSO is the security audit skill — it should not reference other gstack infrastructure.

Copy `cso/SKILL.md` → `skills/cso/SKILL.md`. Apply same stripping.

- [ ] **Step 3: Migrate plan-ceo-review**

Copy `plan-ceo-review/SKILL.md` → `skills/plan-ceo-review/SKILL.md`. Apply same stripping.

This skill writes CEO plans to `~/.gstack/projects/$SLUG/ceo-plans/`. Rewrite to `.claude/gstack/plans/`.

- [ ] **Step 4: Migrate plan-eng-review, plan-design-review, plan-devex-review**

Same pattern for each. Copy, strip preamble, strip host sections, rewrite paths.

- [ ] **Step 5: Migrate office-hours**

Copy `office-hours/SKILL.md` → `skills/office-hours/SKILL.md`. Apply same stripping.

Office-hours may reference GBrain for context loading — delete those sections.

- [ ] **Step 6: Migrate retro**

Copy `retro/SKILL.md` → `skills/retro/SKILL.md`. Apply same stripping.

Retro reads from `~/.gstack/projects/$SLUG/timeline.jsonl` — we dropped timeline logging. Remove timeline references or note that retro will work with git log instead.

- [ ] **Step 7: Migrate autoplan**

Copy `autoplan/SKILL.md` → `skills/autoplan/SKILL.md`. Apply same stripping.

Additionally: update skill invocation references from `/plan-ceo-review` → `/gstack:plan-ceo-review` (and similar for design/eng review). Search for all `/plan-` and `/office-hours` references in the content.

- [ ] **Step 8: Validate Phase 2 skills**

```bash
claude --plugin-dir .
```

Test: `/gstack:review`, `/gstack:office-hours`

Verify: no preamble bash blocks, no `~/.gstack/` paths, methodology content intact.

- [ ] **Step 9: Update MIGRATION.md and commit**

```bash
git add skills/review/ skills/cso/ skills/plan-ceo-review/ skills/plan-eng-review/ skills/plan-design-review/ skills/plan-devex-review/ skills/office-hours/ skills/retro/ skills/autoplan/ MIGRATION.md
git commit -m "feat: migrate Phase 2 skills (review, cso, plan-*, office-hours, retro, autoplan)"
```

---

## Task 6: Phase 3 — Ship & Deploy Skills

**Files:**
- Create: `skills/ship/SKILL.md`
- Create: `skills/land-and-deploy/SKILL.md`
- Create: `skills/canary/SKILL.md`
- Create: `skills/document-release/SKILL.md`
- Create: `skills/benchmark/SKILL.md`
- Create: `skills/benchmark-models/SKILL.md`
- Modify: `MIGRATION.md`

Key differences: ship and land-and-deploy have cross-skill references (read QA test matrices, review checklists). These references may point to `~/.gstack/projects/$SLUG/` paths.

- [ ] **Step 1: Migrate ship**

Copy `ship/SKILL.md` → `skills/ship/SKILL.md`. Apply full stripping pattern.

Ship-specific concerns:
- Uses `gstack-next-version` → keep (on PATH)
- Uses `gstack-review-read` → keep
- Uses `gstack-diff-scope` → keep
- Writes ship test plans to `~/.gstack/projects/$SLUG/` → rewrite to `.claude/gstack/plans/`
- References `/qa` and `/review` → update to `/gstack:qa` and `/gstack:review`
- Checkpoint filtering (squash `[gstack-context]` WIP commits) → delete, we dropped context-save

- [ ] **Step 2: Migrate land-and-deploy, canary, document-release**

Same pattern for each. Apply stripping + path rewrites.

- [ ] **Step 3: Migrate benchmark, benchmark-models**

Copy and strip. These may have lighter preambles.

- [ ] **Step 4: Validate and commit**

```bash
claude --plugin-dir .
```
Test: `/gstack:ship`

```bash
git add skills/ship/ skills/land-and-deploy/ skills/canary/ skills/document-release/ skills/benchmark/ skills/benchmark-models/ MIGRATION.md
git commit -m "feat: migrate Phase 3 skills (ship, land-and-deploy, canary, document-release, benchmark)"
```

---

## Task 7: Phase 4 — Design Skills

**Files:**
- Create: `skills/design-review/SKILL.md`
- Create: `skills/design-consultation/SKILL.md`
- Create: `skills/design-html/SKILL.md`
- Create: `skills/design-shotgun/SKILL.md`
- Create: `skills/devex-review/SKILL.md`
- Modify: `MIGRATION.md`

Design skills may reference:
- `gstack-taste-update` → keep (on PATH), rewrite `~/.gstack/projects/$SLUG/taste-profile.json` → `.claude/gstack/taste-profile.json`
- Browse commands for visual testing → keep references, they'll work once Phase 5 is done
- GPT Image API (design-shotgun) → keep, external service

- [ ] **Step 1: Migrate design-review**

Copy `design-review/SKILL.md` → `skills/design-review/SKILL.md`. Apply full stripping.

Rewrite taste-profile paths. Keep browse command references.

- [ ] **Step 2: Migrate design-consultation, design-html, design-shotgun, devex-review**

Same pattern for each.

- [ ] **Step 3: Validate and commit**

```bash
git add skills/design-review/ skills/design-consultation/ skills/design-html/ skills/design-shotgun/ skills/devex-review/ MIGRATION.md
git commit -m "feat: migrate Phase 4 skills (design-review, design-consultation, design-html, design-shotgun, devex-review)"
```

---

## Task 8: Phase 5 — Browser Skills

**Files:**
- Create: `bin/gstack-browse` (wrapper script)
- Create: `bin/gstack-browse-build`
- Create: `skills/browse/SKILL.md`
- Create: `skills/qa/SKILL.md` + supporting files
- Create: `skills/qa-only/SKILL.md`
- Create: `skills/open-gstack-browser/SKILL.md`
- Modify: `MIGRATION.md`

- [ ] **Step 1: Create browse wrapper script**

Write `bin/gstack-browse`:
```bash
#!/usr/bin/env bash
# Wrapper that locates and runs the browse daemon binary.
# Plugin bin/ is on PATH, so this script is callable as just "gstack-browse".
set -euo pipefail

# Find the plugin root by walking up from this script's location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BROWSE_BIN="$PLUGIN_ROOT/browse/dist/browse"

if [ ! -f "$BROWSE_BIN" ]; then
    echo "gstack-browse: binary not found at $BROWSE_BIN" >&2
    echo "Run: cd $PLUGIN_ROOT/browse && bun run build" >&2
    exit 1
fi

exec "$BROWSE_BIN" "$@"
```

```bash
chmod +x bin/gstack-browse
```

- [ ] **Step 2: Create build helper**

Write `bin/gstack-browse-build`:
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PLUGIN_ROOT/browse"
bun run build
echo "Browse daemon built at: $PLUGIN_ROOT/browse/dist/browse"
```

```bash
chmod +x bin/gstack-browse-build
```

- [ ] **Step 3: Build browse daemon (if not already built)**

```bash
cd browse && bun install && bun run build
```

Verify `browse/dist/browse` exists.

- [ ] **Step 4: Patch browse/src/find-browse.ts**

The spec notes `find-browse.ts` searches for the binary at `~/.claude/skills/gstack/browse/dist/browse`. Add a new search path for plugin mode. In `browse/src/find-browse.ts`, add `${CLAUDE_PLUGIN_ROOT}/browse/dist/browse` to the search order (read from env var). If `CLAUDE_PLUGIN_ROOT` is not set, fall back to existing paths.

After patching, rebuild: `cd browse && bun run build`

- [ ] **Step 5: Migrate browse skill**

Copy `browse/SKILL.md` → `skills/browse/SKILL.md`. Apply stripping.

The browse SKILL.md is the largest (~38KB auto-generated). It contains the full command reference. Strip preamble but keep the command documentation intact.

Update any hardcoded paths like `~/.claude/skills/gstack/browse/dist/browse` → `gstack-browse` (on PATH).

- [ ] **Step 6: Migrate qa skill**

Copy `qa/SKILL.md` → `skills/qa/SKILL.md`. Apply full stripping.

QA-specific: uses browse commands heavily. References should work via `gstack-browse` on PATH.

Copy any supporting files from `qa/` (scripts, templates).

- [ ] **Step 7: Migrate qa-only, open-gstack-browser**

Same pattern.

- [ ] **Step 8: Test browse integration**

```bash
claude --plugin-dir .
```

Test: `/gstack:browse` — verify command reference loads.

If browse daemon is built, test a simple browse command to verify the wrapper works.

- [ ] **Step 9: Commit**

```bash
git add bin/gstack-browse bin/gstack-browse-build skills/browse/ skills/qa/ skills/qa-only/ skills/open-gstack-browser/ MIGRATION.md
git commit -m "feat: migrate Phase 5 skills (browse, qa, qa-only, open-gstack-browser) with daemon wrapper"
```

---

## Task 9: Phase 6 — Infrastructure Skills & Cleanup

**Files:**
- Create: `skills/setup-deploy/SKILL.md`
- Create: `skills/setup-browser-cookies/SKILL.md`
- Create: `skills/plan-tune/SKILL.md`
- Create: `skills/health/SKILL.md` (rewritten)
- Modify: `MIGRATION.md`

- [ ] **Step 1: Migrate setup-deploy, setup-browser-cookies, plan-tune**

Copy each, apply standard stripping.

- [ ] **Step 2: Rewrite health skill**

Write `skills/health/SKILL.md` from scratch (not copy):

```markdown
---
name: health
description: Health check for gstack plugin. Verifies bin scripts, browse daemon, state directories, and learnings.
disable-model-invocation: true
allowed-tools: Bash Read
---

# gstack Health Check

Run these checks to verify plugin health:

## 1. Plugin Structure
```bash
ls .claude-plugin/plugin.json && echo "plugin.json: OK" || echo "plugin.json: MISSING"
ls hooks/hooks.json && echo "hooks.json: OK" || echo "hooks.json: MISSING"
```

## 2. Bin Scripts on PATH
```bash
for cmd in gstack-slug gstack-learnings-log gstack-learnings-search gstack-diff-scope gstack-review-log gstack-review-read gstack-next-version gstack-taste-update gstack-browse; do
  which "$cmd" &>/dev/null && echo "$cmd: OK" || echo "$cmd: NOT ON PATH"
done
```

## 3. Browse Daemon
```bash
gstack-browse --version 2>/dev/null && echo "browse: OK" || echo "browse: NOT BUILT (run gstack-browse-build)"
```

## 4. Project State
```bash
ls .claude/gstack/learnings.jsonl 2>/dev/null && echo "learnings: OK ($(wc -l < .claude/gstack/learnings.jsonl) entries)" || echo "learnings: NOT INITIALIZED"
```

## 5. Upstream Sync
```bash
git remote get-url upstream 2>/dev/null && echo "upstream: OK" || echo "upstream: NOT CONFIGURED"
```

Report all results.
```

- [ ] **Step 3: Evaluate landing-report**

Read `landing-report/SKILL.md`. If it's useful, migrate it. If it's mostly GBrain/telemetry infrastructure, drop it.

- [ ] **Step 4: Clean up _test skill**

Remove `skills/_test/SKILL.md` and `bin/gstack-test-path` — they were only for spike validation.

```bash
rm -rf skills/_test bin/gstack-test-path
```

- [ ] **Step 5: Update MIGRATION.md and commit**

Mark Phase 6 complete. Mark dropped skills as "Dropped" in the manifest.

```bash
git add skills/setup-deploy/ skills/setup-browser-cookies/ skills/plan-tune/ skills/health/ MIGRATION.md
git rm -r skills/_test bin/gstack-test-path
git commit -m "feat: migrate Phase 6 skills (setup-deploy, setup-browser-cookies, plan-tune, health)"
```

---

## Task 10: Post-Migration Cleanup

**Files:**
- Delete: root-level skill dirs (43 directories)
- Delete: `setup`, `hosts/`, template pipeline files
- Delete: `extension/`, `supabase/`, `design/dist/`, `make-pdf/dist/`
- Delete: host-variant dirs, obsolete docs
- Delete: dropped bin scripts
- Modify: `MIGRATION.md`, `README.md`

- [ ] **Step 1: Delete root-level skill directories**

These are the original skill locations, now migrated to `skills/`:

```bash
rm -rf autoplan benchmark benchmark-models canary careful claude codex context-restore context-save contrib cso design-consultation design-html design-review design-shotgun devex-review document-release freeze gstack-upgrade guard health investigate land-and-deploy landing-report learn make-pdf office-hours open-gstack-browser openclaw pair-agent plan-ceo-review plan-design-review plan-devex-review plan-eng-review plan-tune qa qa-only retro review setup-browser-cookies setup-deploy setup-gbrain ship unfreeze
```

- [ ] **Step 2: Delete install infrastructure**

```bash
rm -f setup
rm -rf hosts/
rm -rf scripts/gen-skill-docs.ts scripts/discover-skills.ts scripts/resolvers/
rm -f SKILL.md.tmpl
rm -f SKILL.md  # root auto-generated browse doc
rm -f conductor.json
rm -f .gitlab-ci.yml
rm -f actionlint.yaml
```

- [ ] **Step 3: Delete extension, telemetry, separate tools**

```bash
rm -rf extension/
rm -rf supabase/
rm -rf design/dist/ make-pdf/dist/
rm -rf model-overlays/
```

- [ ] **Step 4: Delete host-variant directories**

```bash
rm -rf .agents/ .codex/ .factory/ .opencode/
```

Note: verify these exist before deleting — they may only appear after running setup.

- [ ] **Step 5: Delete dropped bin scripts**

Keep only the migrated scripts. Delete everything else:

```bash
cd bin
# List what to keep
KEEP="gstack-browse gstack-browse-build gstack-slug gstack-learnings-log gstack-learnings-search gstack-diff-scope gstack-review-log gstack-review-read gstack-next-version gstack-taste-update gstack-specialist-stats"

for f in *; do
    if ! echo "$KEEP" | grep -qw "$f"; then
        rm -f "$f"
    fi
done
cd ..
```

- [ ] **Step 6: Delete obsolete documentation**

```bash
rm -f TODOS.md ETHOS.md CONTRIBUTING.md USING_GBRAIN_WITH_GSTACK.md
rm -f ARCHITECTURE.md BROWSER.md DESIGN.md AGENTS.md CHANGELOG.md
```

Keep: `README.md` (will rewrite), `CLAUDE.md` (already rewritten), `LICENSE`.

- [ ] **Step 7: Rewrite README.md**

Write a new `README.md` documenting the native plugin:

```markdown
# gstack — Claude Code Plugin

Virtual engineering team: 43 specialist skills for code review, QA, planning, design, shipping, and browser automation.

Forked from [garrytan/gstack](https://github.com/garrytan/gstack) and converted to native Claude Code plugin format.

## Install

```bash
claude --plugin-dir /path/to/gstack
```

Or add to your settings.json plugin list.

## Skills

### Review & Quality
- `/gstack:review` — Pre-landing PR review
- `/gstack:cso` — OWASP Top 10 security audit
- `/gstack:qa` — QA with real browser testing
- `/gstack:qa-only` — QA report without code changes

### Planning
- `/gstack:office-hours` — YC-style office hours brainstorm
- `/gstack:plan-ceo-review` — Strategic review
- `/gstack:plan-eng-review` — Architecture review
- `/gstack:plan-design-review` — Design audit
- `/gstack:autoplan` — Automated multi-review pipeline

### Shipping
- `/gstack:ship` — Release engineer (test, build, PR)
- `/gstack:land-and-deploy` — Merge and deploy
- `/gstack:canary` — Post-deploy monitoring

### Design
- `/gstack:design-review` — Design audit with fixes
- `/gstack:design-shotgun` — Visual design exploration

### Browser
- `/gstack:browse` — Headless browser with persistent sessions
- `/gstack:open-gstack-browser` — Launch headed browser

### Safety
- `/gstack:careful` — Destructive command guardrails
- `/gstack:freeze` / `/gstack:unfreeze` — Lock/unlock file changes

## License

See LICENSE file.
```

- [ ] **Step 8: Final validation**

```bash
claude --plugin-dir .
```

Run `/gstack:health` to check everything.
Try a few skills: `/gstack:review`, `/gstack:careful`, `/gstack:browse`.

- [ ] **Step 9: Update MIGRATION.md — mark complete**

Mark Post-Migration as complete.

- [ ] **Step 10: Commit cleanup**

```bash
git add -A
git commit -m "chore: post-migration cleanup — delete original skill dirs, install scripts, host configs, telemetry"
```

- [ ] **Step 11: Final commit — migration complete**

```bash
git add MIGRATION.md README.md
git commit -m "docs: finalize migration — update README and mark MIGRATION.md complete"
```
