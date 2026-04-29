# gstack Native Plugin Migration — Design Spec

**Date:** 2026-04-29
**Author:** Peter Yu
**Status:** Approved
**Source:** Forked from [garrytan/gstack](https://github.com/garrytan/gstack)

**Rev:** 2 (post-Codex review — added state audit, bin/ deps, browse path fix, Phase 0 split)

## Goal

Convert gstack from a custom-installed skill collection (1011-line setup script, symlink-based discovery, multi-host support) into a native Claude Code plugin using `.claude-plugin/plugin.json` manifest format. Eliminate all custom install infrastructure while preserving all 43 skill methodologies and the browse daemon.

## Constraints

- Personal toolbox + learning exercise (not for marketplace distribution)
- Claude Code only (no Codex/Cursor/Factory/Kiro/OpenClaw/Hermes/GBrain)
- Upstream sync capability must be maintained
- Browse daemon kept intact (persistent sessions + prompt injection defense)
- Template generation pipeline eliminated (SKILL.md edited directly)

## 1. Target Plugin Structure

```
gstack/
├── .claude-plugin/
│   └── plugin.json              # manifest
├── skills/                      # all 43 skills
│   ├── _context/
│   │   └── SKILL.md             # shared context skill (not user-invocable)
│   ├── review/
│   │   └── SKILL.md
│   ├── qa/
│   │   ├── SKILL.md
│   │   └── scripts/
│   ├── browse/
│   │   └── SKILL.md
│   └── ... (remaining skills)
├── agents/                      # subagent definitions if needed
├── hooks/
│   └── hooks.json               # SessionStart hook
├── bin/
│   ├── gstack-browse            # CLI wrapper → browse/dist/browse
│   ├── gstack-browse-build      # rebuild script
│   ├── gstack-slug              # project slug + branch detection
│   ├── gstack-learnings-search  # search learnings.jsonl
│   ├── gstack-learnings-log     # append to learnings.jsonl
│   ├── gstack-diff-scope        # diff scope analysis (review/ship)
│   ├── gstack-review-read       # read prior review results
│   ├── gstack-review-log        # write review results
│   ├── gstack-next-version      # version bumping (ship)
│   └── gstack-taste-update      # design taste profile
├── browse/
│   └── src/                     # browse daemon source
├── .mcp.json                    # future: browse as MCP server
├── settings.json                # plugin default settings
├── MIGRATION.md                 # tracking manifest
├── CLAUDE.md                    # plugin dev instructions
└── scripts/
    └── upstream-diff.sh         # sync diff script
```

### plugin.json

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

## 2. Sync Strategy

### Setup

- `upstream` remote → `https://github.com/garrytan/gstack.git`
- `upstream-mirror` branch — clean pull from upstream, never modified
- `main` branch — native plugin (your working branch)

### Workflow

1. `git fetch upstream`
2. Merge `upstream/master` into `upstream-mirror`
3. Run `scripts/upstream-diff.sh` — strips preamble, compares skill methodology content
4. Manually port relevant changes from mirror → main

### Diff Script

`scripts/upstream-diff.sh` compares upstream SKILL.md files (preamble-stripped) against migrated versions. Detects:
- Changed methodology in existing skills
- New skills added upstream
- Deleted skills

## 3. Preamble Replacement

### Current preamble (~80 lines per skill)

Full audit reveals the preamble does far more than version/config checks. Each skill's preamble:

1. **Version/update check** — `gstack-update-check`, upgrade prompts
2. **Session tracking** — creates `~/.gstack/sessions/$PPID`, cleans stale sessions
3. **Config loading** — `gstack-config get` for ~10 keys (proactive, telemetry, explain_level, question_tuning, checkpoint_mode, etc.)
4. **Learnings** — `gstack-slug` → construct path → `gstack-learnings-search`
5. **Timeline logging** — `gstack-timeline-log` at start and end
6. **Telemetry** — append to `~/.gstack/analytics/skill-usage.jsonl`, call `gstack-telemetry-log`
7. **Question logging** — `gstack-question-log` for every AskUserQuestion
8. **Question tuning** — `gstack-question-preference --check` before each question
9. **GBrain sync** — `gstack-brain-init`, `gstack-brain-restore`, `gstack-brain-sync`
10. **First-time prompts** — telemetry consent, proactive consent, routing injection, lake principle, writing style, feature discovery (7+ marker files)
11. **Vendoring deprecation** — detect and offer migration from vendored installs
12. **Review logging** — `gstack-review-log`, `gstack-review-read` (review/ship only)
13. **Specialist stats** — `gstack-specialist-stats` (review/ship only)

### What stays

| Function | Replacement |
|---|---|
| Project learnings loading | `_context` shared skill + SessionStart hook |
| Project context | `_context` shared skill |
| Learnings writing | `_context` shared skill (append instruction) |

### What gets dropped

| Function | Reason |
|---|---|
| Version/update check | Native plugin handles updates |
| Session tracking | Native Claude Code sessions |
| Config loading (gstack-config) | Native settings.json / userConfig |
| Timeline logging | Not needed for personal use |
| Telemetry (local + remote) | Dropped entirely |
| Question logging | Not needed for personal use |
| Question tuning | Not needed for personal use |
| GBrain sync | GBrain not supported |
| First-time prompts (7+ markers) | No onboarding needed |
| Vendoring deprecation | No vendored installs |
| Review logging | Evaluate per-skill — keep if review skills use it |
| Specialist stats | Evaluate per-skill — keep if review skills use it |

### Bin scripts disposition

Skills call ~20 `gstack-*` bin scripts. Disposition:

| Script | Action |
|---|---|
| `gstack-update-check` | Drop |
| `gstack-config` | Drop — use native settings |
| `gstack-repo-mode` | Drop — not needed |
| `gstack-slug` | **Keep** — provides SLUG and BRANCH vars, used by learnings |
| `gstack-learnings-search` | **Keep** — searches learnings.jsonl |
| `gstack-learnings-log` | **Keep** — appends to learnings.jsonl |
| `gstack-timeline-log` | Drop |
| `gstack-brain-*` | Drop — GBrain not supported |
| `gstack-team-init` | Drop |
| `gstack-question-preference` | Drop |
| `gstack-question-log` | Drop |
| `gstack-telemetry-log` | Drop |
| `gstack-diff-scope` | **Keep** — used by review/ship for diff analysis |
| `gstack-review-read` | **Keep** — reads prior reviews |
| `gstack-review-log` | **Keep** — writes review results |
| `gstack-specialist-stats` | **Evaluate** — adaptive review gating |
| `gstack-next-version` | **Keep** — version bumping for ship |
| `gstack-taste-update` | **Keep** — design taste profile |

Kept scripts (~8) move to plugin `bin/`. Paths rewritten from `~/.gstack/` to `.claude/gstack/`.

### SessionStart Hook (`hooks/hooks.json`)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .claude/gstack && touch .claude/gstack/learnings.jsonl && echo '{\"learnings_path\": \".claude/gstack/learnings.jsonl\", \"project\": \"'$(basename $(pwd))'\"}'",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

### Shared Context Skill (`skills/_context/SKILL.md`)

```yaml
---
name: _context
description: Project context and learnings for gstack skills
user-invocable: false
---

## Project Learnings

When starting work, check `.claude/gstack/learnings.jsonl` for prior
learnings in this project. Apply relevant ones silently.

When completing work that produced a reusable insight, append to
learnings.jsonl:
{"timestamp":"ISO","skill":"skill-name","learning":"one-line insight"}

## Project Context

Check recent git history and README for project awareness before
executing skill-specific methodology.
```

## 4. Browse Daemon Integration

### Architecture (kept intact)

- Bun HTTP server + Playwright Chromium
- Ref system (`@e1`, `@e2`) for accessibility tree navigation
- 6-layer prompt injection defense (BERT + Haiku + canary + ensemble)
- Persistent sessions, cookies, tabs

### Plugin integration

- Pre-built binary stays at `browse/dist/browse` (current build output location)
- Wrapper script in `bin/gstack-browse` calls `browse/dist/browse` via `${CLAUDE_PLUGIN_ROOT}`
- `bin/` auto-added to Bash tool PATH by plugin system
- Source kept in `browse/src/` for rebuilds
- Browse state is **project-local** at `.gstack/browse.json` (per current `browse/src/config.ts` behavior — NOT global)
- Browse logs also project-local: `.gstack/browse-console.log`, `.gstack/browse-network.log`, `.gstack/browse-audit.jsonl`

**Note:** `browse/src/find-browse.ts` searches for binary at `~/.claude/skills/gstack/browse/dist/browse` and similar paths. Must be patched to also check `${CLAUDE_PLUGIN_ROOT}/browse/dist/browse` for plugin mode.

### Stripped from browse

- Tunnel/dual-listener architecture (ngrok remote access)
- Multi-host PATH detection
- macOS Apple Silicon auto-codesigning

## 5. State Management

### Project-local (`.claude/gstack/`)

```
.claude/gstack/
├── learnings.jsonl          # compound knowledge
├── plans/                   # saved review plans
├── reviews/                 # per-branch review results (${BRANCH}-reviews.jsonl)
├── taste-profile.json       # design preference profile
└── config.yaml              # project-specific overrides
```

Created by SessionStart hook. Add `.claude/gstack/` to project `.gitignore`.

### Project-local browse state (`.gstack/`)

Browse daemon uses its own `.gstack/` dir at project root (per current `browse/src/config.ts`):

```
.gstack/
├── browse.json              # daemon PID, port, token
├── browse-console.log       # browser console output
├── browse-network.log       # network request/response log
└── browse-audit.jsonl       # audit trail
```

This is the existing behavior — no change needed.

### Global (`~/.gstack/`) — minimal

```
~/.gstack/
├── models/              # ONNX classifier cache (prompt injection)
└── security/
    └── attempts.jsonl   # prompt injection attempt log
```

### Dropped

| Item | Reason |
|---|---|
| `~/.gstack/config.yaml` | Use native settings.json |
| `~/.gstack/sessions/` | Native session tracking |
| `~/.gstack/analytics/` | Telemetry dropped |
| `~/.gstack/projects/${SLUG}/timeline.jsonl` | Not needed for personal use |
| `~/.gstack/.telemetry-prompted` + 6 other markers | No onboarding flow |
| `~/.gstack/.git/` (GBrain repo) | GBrain dropped |
| `~/.gstack/.brain-*` files | GBrain dropped |

## 6. Migration Phases

### Phase 0A — Plugin Scaffold + Spike Validation

- Create `.claude-plugin/plugin.json`
- Create `skills/`, `hooks/`, `bin/` directories
- Create `hooks/hooks.json` (SessionStart hook)
- Create `skills/_context/SKILL.md` (shared context skill)
- Create one trivial test skill (`skills/_test/SKILL.md`) to validate:
  - `claude --plugin-dir .` loads plugin
  - `/gstack:_test` invokes correctly
  - `bin/` PATH injection works (add a test script to `bin/`)
  - Hook fires on session start
- Create `MIGRATION.md`
- **Gate: plugin scaffold works before proceeding**
- Commit

### Phase 0B — Shared Runtime Replacement

- Copy kept bin scripts (~8) to plugin `bin/`
- Rewrite paths in kept scripts: `~/.gstack/projects/${SLUG}/` → `.claude/gstack/`
- Patch `gstack-slug` to work without `gstack-config`
- Test: `gstack-slug`, `gstack-learnings-log`, `gstack-learnings-search` work from plugin `bin/`
- Set up upstream remote + `upstream-mirror` branch
- Create `scripts/upstream-diff.sh`
- Add plugin `CLAUDE.md`
- **Gate: shared runtime scripts work before migrating skills**
- Commit

### Phase 1 — Simple Standalone Skills (~6)

`careful`, `freeze`, `guard`, `unfreeze`, `learn`, `investigate`

Purpose: prove migration checklist. Iron out stripping process.

### Phase 2 — Review & Planning Skills (~9)

`review`, `cso`, `plan-ceo-review`, `plan-eng-review`, `plan-design-review`, `plan-devex-review`, `office-hours`, `retro`, then `autoplan`

### Phase 3 — Ship & Deploy Skills (~6)

`ship`, `land-and-deploy`, `canary`, `document-release`, `benchmark`, `benchmark-models`

Update cross-skill references to new paths.

### Phase 4 — Design Skills (~5)

`design-review`, `design-consultation`, `design-html`, `design-shotgun`, `devex-review`

### Phase 5 — Browser Skills (~4)

1. Copy browse daemon binary to `bin/`
2. Migrate: `browse`, `qa`, `qa-only`, `open-gstack-browser`
3. Drop: `pair-agent` (tunnel dependency removed)

### Phase 6 — Infrastructure & Cleanup (~8)

| Skill | Action |
|---|---|
| `context-save` | Drop — native Claude Code memory replaces this |
| `context-restore` | Drop — native Claude Code memory replaces this |
| `gstack-upgrade` | Drop — native plugin updates |
| `health` | Rewrite — check plugin state |
| `codex` | Drop — Codex-specific |
| `setup-gbrain` | Drop — GBrain-specific |
| `setup-deploy` | Keep |
| `setup-browser-cookies` | Keep |
| `plan-tune` | Keep |
| `landing-report` | Evaluate |
| `make-pdf` | Drop |
| `openclaw` | Drop — host-specific |
| `claude` | Drop — meta-skill |
| `contrib` | Drop — contributor guide |

### Post-Migration Cleanup

Delete: root-level skill dirs, `setup`, `hosts/`, `scripts/gen-skill-docs.ts`, resolvers, `extension/`, `supabase/`, `design/dist/`, `make-pdf/dist/`, host-variant dirs, `SKILL.md.tmpl`, root `SKILL.md`, `conductor.json`, `.gitlab-ci.yml`, `TODOS.md`, `ETHOS.md`, `CONTRIBUTING.md`.

## 7. Per-Skill Migration Checklist

```
□ Copy {skill}/SKILL.md → skills/{skill}/SKILL.md
□ Copy supporting files (scripts/, *.md) if any
□ Strip preamble block (~80 lines, see Section 3 for full inventory)
□ Strip host-specific sections (Codex/Cursor/Factory/etc.)
□ Strip template markers ({{PREAMBLE}}, {{COMMAND_REFERENCE}}, etc.)
□ Strip gstack-specific calls (question-log, timeline-log, telemetry-log, brain-*)
□ Rewrite ~/.gstack/projects/${SLUG}/ paths → .claude/gstack/
□ Rewrite gstack-* bin script calls to only use kept scripts (see Section 3 disposition table)
□ Update frontmatter (description, allowed-tools)
□ Add _context skill reference if skill uses learnings
□ Test: claude --plugin-dir . then invoke /gstack:{skill}
□ Commit (one commit per skill or per batch)
□ Update MIGRATION.md
```

## 8. De-Bloat Impact

### Deleted

| Item | Size | Reason |
|---|---|---|
| `setup` script | 1,011 lines | Native plugin discovery |
| Template pipeline | ~300KB TS | Flattened |
| Host configs (8) | ~40KB | Claude Code only |
| `extension/` | Chrome sidebar | Not relevant |
| `supabase/` | Telemetry backend | Dropped |
| `design/dist/`, `make-pdf/dist/` | ~116MB | Separate tools |
| Host variant dirs | Multiple | Claude Code only |
| Preamble × 43 | ~3,440 lines | Hook + shared skill |
| Host sections × 43 | ~2,000+ lines | Claude Code only |

### Estimated Result

| Metric | Before | After |
|---|---|---|
| Repo size | 134MB | ~65MB |
| SKILL.md total lines | ~48,000 | ~30,000 |
| Shell scripts in bin/ | 60+ | ~10 |
| State locations | 4+ | 2 |
| Install script | 1,011 lines | 0 |
| Build tooling | ~300KB | 0 |
