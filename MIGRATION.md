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
- [x] careful
- [x] freeze
- [x] guard
- [x] unfreeze
- [x] learn
- [x] investigate

## Phase 2: Review & Planning Skills
- [x] review
- [x] cso
- [x] plan-ceo-review
- [x] plan-eng-review
- [x] plan-design-review
- [x] plan-devex-review
- [x] office-hours
- [x] retro
- [x] autoplan

## Phase 3: Ship & Deploy Skills
- [x] ship
- [x] land-and-deploy
- [x] canary
- [x] document-release
- [x] benchmark
- [x] benchmark-models

## Phase 4: Design Skills
- [x] design-review
- [x] design-consultation
- [x] design-html
- [x] design-shotgun
- [x] devex-review

## Phase 5: Browser Skills
- [x] browse daemon in bin/
- [x] browse
- [x] qa
- [x] qa-only
- [x] open-gstack-browser

## Phase 6: Infrastructure & Cleanup
- [x] setup-deploy
- [x] setup-browser-cookies
- [x] ~~plan-tune~~ (dropped — depends on gstack-developer-profile, gstack-question-preference, gstack-config which are not migrated)
- [x] health (rewrite)
- [x] landing-report (migrated — standalone version queue dashboard methodology)
- [x] Drop: context-save, context-restore, gstack-upgrade, codex, setup-gbrain, make-pdf, openclaw, claude, contrib

## Post-Migration
- [ ] Delete root-level skill dirs
- [ ] Delete setup, hosts/, template pipeline
- [ ] Delete extension/, supabase/, design/dist/, make-pdf/dist/
- [ ] Update README.md
