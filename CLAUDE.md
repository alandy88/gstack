# gstack — Native Claude Code Plugin

Forked from [garrytan/gstack](https://github.com/garrytan/gstack) and converted to native Claude Code plugin format.

## Development

Load plugin for testing:
```bash
claude --plugin-dir .
```

Reload after changes: `/reload-plugins`

## Upstream Sync

```bash
git fetch upstream
git checkout upstream-mirror && git merge upstream/main && git checkout main
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

## Commands

```bash
bun install          # install dependencies
bun run build        # build browse daemon
bun test             # run free tests
```
