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
