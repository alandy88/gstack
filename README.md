# gstack — Claude Code Plugin

Virtual engineering team: 43 specialist skills for code review, QA, planning, design, shipping, and browser automation.

Forked from [garrytan/gstack](https://github.com/garrytan/gstack) and converted to native Claude Code plugin format.

## Install

```bash
claude --plugin-dir /path/to/gstack
```

Or add to your Claude Code settings.json plugin list.

## First Run

Build the browse daemon (required for browser skills):
```bash
gstack-browse-build
```

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
- `/gstack:plan-devex-review` — Developer experience review
- `/gstack:autoplan` — Automated multi-review pipeline

### Shipping
- `/gstack:ship` — Release engineer (test, build, PR)
- `/gstack:land-and-deploy` — Merge and deploy
- `/gstack:canary` — Post-deploy monitoring
- `/gstack:document-release` — Post-ship doc updates
- `/gstack:benchmark` — Performance regression detection
- `/gstack:benchmark-models` — Model performance comparison

### Design
- `/gstack:design-review` — Design audit with fixes
- `/gstack:design-consultation` — Design system from scratch
- `/gstack:design-html` — HTML/CSS design iteration
- `/gstack:design-shotgun` — Visual design exploration
- `/gstack:devex-review` — Developer experience audit

### Browser
- `/gstack:browse` — Headless browser with persistent sessions
- `/gstack:qa` — QA with real browser testing
- `/gstack:open-gstack-browser` — Launch headed browser

### Safety
- `/gstack:careful` — Destructive command guardrails
- `/gstack:freeze` / `/gstack:unfreeze` — Lock/unlock file changes
- `/gstack:guard` — Protected operations

### Investigation
- `/gstack:investigate` — Systematic root-cause debugging
- `/gstack:learn` — Extract and apply project learnings
- `/gstack:retro` — Weekly engineering retrospective

### Setup
- `/gstack:setup-deploy` — One-time deploy config
- `/gstack:setup-browser-cookies` — Browser cookie setup
- `/gstack:health` — Plugin health check

## Health Check

Run `/gstack:health` to verify plugin is working correctly.

## Upstream Sync

```bash
git fetch upstream
scripts/upstream-diff.sh
```

## License

See LICENSE file.
