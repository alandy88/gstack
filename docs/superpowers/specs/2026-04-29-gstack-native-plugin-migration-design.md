# gstack Native Plugin Migration — Design Spec

**Date:** 2026-04-29
**Author:** Peter Yu
**Status:** Approved
**Source:** Forked from [garrytan/gstack](https://github.com/garrytan/gstack)

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
│   ├── gstack-browse-server     # compiled browse daemon binary
│   ├── gstack-browse            # CLI wrapper (start/stop/status/command)
│   └── gstack-browse-build      # rebuild script
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

Checks: version updates, session count, config, telemetry, learnings, routing, checkpoint mode.

### What stays

| Function | Replacement |
|---|---|
| Project learnings loading | `_context` shared skill + SessionStart hook |
| Project context | `_context` shared skill |

### What gets dropped

Version/update check, session count/ELI16, config loading, telemetry, routing suggestions — all replaced by native plugin infrastructure.

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

- Pre-built binary committed to `bin/` (~58MB)
- `bin/` auto-added to Bash tool PATH by plugin system
- Source kept in `browse/src/` for rebuilds
- State at `~/.gstack/browse.json` (global singleton — exception to project-local rule)

### Stripped from browse

- Tunnel/dual-listener architecture (ngrok remote access)
- Multi-host PATH detection
- macOS Apple Silicon auto-codesigning

## 5. State Management

### Project-local (`.claude/gstack/`)

```
.claude/gstack/
├── learnings.jsonl      # compound knowledge
├── plans/               # saved review plans
└── config.yaml          # project-specific overrides
```

Created by SessionStart hook. Add `.claude/gstack/` to project `.gitignore`.

### Global (`~/.gstack/`) — minimal

```
~/.gstack/
├── browse.json          # daemon PID, port, token
├── models/              # ONNX classifier cache
└── security/
    └── attempts.jsonl   # prompt injection log
```

### Dropped

- `~/.gstack/config.yaml` (global config)
- `~/.gstack/sessions/` (session tracking)
- `~/.gstack/analytics/` (telemetry)
- `~/.gstack/.last-setup-version`, `.welcome-seen`, `.telemetry-prompted`, `.proactive-prompted`

## 6. Migration Phases

### Phase 0 — Scaffold

- Create `.claude-plugin/plugin.json`
- Create `skills/`, `hooks/`, `bin/` directories
- Create `hooks/hooks.json`, `skills/_context/SKILL.md`
- Create `MIGRATION.md`
- Set up upstream remote + `upstream-mirror` branch
- Create `scripts/upstream-diff.sh`
- Add plugin `CLAUDE.md`
- Test: `claude --plugin-dir .` loads empty plugin
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
□ Strip preamble block (~80 lines)
□ Strip host-specific sections (Codex/Cursor/Factory/etc.)
□ Strip template markers ({{PREAMBLE}}, {{COMMAND_REFERENCE}}, etc.)
□ Rewrite ~/.gstack/ paths → .claude/gstack/
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
