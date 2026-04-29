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
