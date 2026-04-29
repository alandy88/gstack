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
