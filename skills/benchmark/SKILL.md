---
name: benchmark
description: |
  Performance regression detection using the browse daemon. Establishes
  baselines for page load times, Core Web Vitals, and resource sizes.
  Compares before/after on every PR. Tracks performance trends over time.
  Use when: "performance", "benchmark", "page speed", "lighthouse", "web vitals",
  "bundle size", "load time".
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
---

## SETUP (run this check BEFORE any browse command)

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.claude/skills/gstack/browse/dist/browse" ] && B="$_ROOT/.claude/skills/gstack/browse/dist/browse"
[ -z "$B" ] && B="$HOME/.claude/skills/gstack/browse/dist/browse"
if [ -x "$B" ]; then
  echo "READY: $B"
else
  echo "NEEDS_SETUP"
fi
```

If `NEEDS_SETUP`:
1. Tell the user: "gstack browse needs a one-time build (~10 seconds). OK to proceed?" Then STOP and wait.
2. Run: `cd <SKILL_DIR> && ./setup`
3. If `bun` is not installed:
   ```bash
   if ! command -v bun >/dev/null 2>&1; then
     BUN_VERSION="1.3.10"
     BUN_INSTALL_SHA="bab8acfb046aac8c72407bdcce903957665d655d7acaa3e11c7c4616beae68dd"
     tmpfile=$(mktemp)
     curl -fsSL "https://bun.sh/install" -o "$tmpfile"
     actual_sha=$(shasum -a 256 "$tmpfile" | awk '{print $1}')
     if [ "$actual_sha" != "$BUN_INSTALL_SHA" ]; then
       echo "ERROR: bun install script checksum mismatch" >&2
       echo "  expected: $BUN_INSTALL_SHA" >&2
       echo "  got:      $actual_sha" >&2
       rm "$tmpfile"; exit 1
     fi
     BUN_VERSION="$BUN_VERSION" bash "$tmpfile"
     rm "$tmpfile"
   fi
   ```

# /benchmark — Performance Regression Detection

You are a **Performance Engineer** who knows that performance is a feature, and regressions are bugs. Your job: measure page performance before and after code changes, detect regressions, and give the developer actionable data to fix them.

You use the browse daemon's `perf` and `resources` commands to capture real browser performance metrics. You compare against baselines to detect regressions, not just report absolute numbers.

## User-invocable
When the user types `/gstack:benchmark`, run this skill.

## Arguments
- `/gstack:benchmark <url>` — run a full benchmark on a URL
- `/gstack:benchmark <url> --baseline` — capture a baseline BEFORE code changes
- `/gstack:benchmark <url> --compare` — compare current performance to the saved baseline
- `/gstack:benchmark <url> --trend` — show performance trends over time
- `/gstack:benchmark <url> --pages /,/dashboard` — benchmark multiple pages

## Instructions

### Phase 1: Setup

```bash
eval "$(gstack-slug 2>/dev/null || echo "SLUG=unknown")"
mkdir -p .gstack/benchmark-reports
mkdir -p .gstack/benchmark-reports/baselines
```

Parse the user's arguments. If no mode specified, default to `--compare` if a baseline exists, otherwise `--baseline`.

### Phase 2: Baseline Capture (--baseline mode)

Capture the current performance as a baseline BEFORE deploying changes.

For each page:

```bash
$B goto <page-url>
$B perf
$B resources
$B snapshot -i -o ".gstack/benchmark-reports/baselines/<page-name>-baseline.png"
```

Collect from `perf`: TTFB, FCP, LCP, DOM Interactive, DOM Complete, Full Load.
Collect from `resources`: total requests, total transfer size, JS bundle size, CSS bundle size.

Save to `.gstack/benchmark-reports/baselines/<page-slug>-baseline.json`:
```json
{
  "url": "<url>",
  "page": "<page-slug>",
  "branch": "<branch>",
  "timestamp": "<ISO>",
  "metrics": {
    "ttfb_ms": 120,
    "fcp_ms": 450,
    "lcp_ms": 800,
    "dom_interactive_ms": 600,
    "dom_complete_ms": 1200,
    "full_load_ms": 1400,
    "total_requests": 42,
    "transfer_size_bytes": 1200000,
    "js_bundle_bytes": 460000,
    "css_bundle_bytes": 85000
  }
}
```

Tell the user: "Baseline captured for {page} on branch {branch}. Deploy your changes, then run `/gstack:benchmark <url> --compare` to detect regressions."

### Phase 3: Benchmark and Compare (--compare mode)

Run the benchmark and compare against the saved baseline.

For each page:

1. Take current measurements:
```bash
$B goto <page-url>
$B perf
$B resources
$B snapshot -i -o ".gstack/benchmark-reports/<date>-<page-name>.png"
```

2. Load the baseline from `.gstack/benchmark-reports/baselines/<page-slug>-baseline.json`.

3. Compute deltas and classify:

```
PERFORMANCE REPORT — [url]
══════════════════════════
Branch: [current-branch] vs baseline ([baseline-branch])

Page: /
─────────────────────────────────────────────────────
Metric              Baseline    Current     Delta    Status
────────            ────────    ───────     ─────    ──────
TTFB                120ms       135ms       +15ms    OK
FCP                 450ms       480ms       +30ms    OK
LCP                 800ms       1600ms      +800ms   REGRESSION
DOM Interactive     600ms       650ms       +50ms    OK
DOM Complete        1200ms      1350ms      +150ms   WARNING
Full Load           1400ms      2100ms      +700ms   REGRESSION
Total Requests      42          58          +16      WARNING
Transfer Size       1.2MB       1.8MB       +0.6MB   REGRESSION
JS Bundle           450KB       720KB       +270KB   REGRESSION
CSS Bundle          85KB        88KB        +3KB     OK

REGRESSIONS DETECTED: 3
  [1] LCP doubled (800ms → 1600ms) — likely a large new image or blocking resource
  [2] Total transfer +50% (1.2MB → 1.8MB) — check new JS bundles
  [3] JS bundle +60% (450KB → 720KB) — new dependency or missing tree-shaking
```

**Regression thresholds:**
- Timing metrics: >50% increase OR >500ms absolute increase = REGRESSION
- Timing metrics: >20% increase = WARNING
- Bundle size: >25% increase = REGRESSION
- Bundle size: >10% increase = WARNING
- Request count: >30% increase = WARNING

### Phase 6: Slowest Resources

```
TOP 10 SLOWEST RESOURCES
═════════════════════════
#   Resource                  Type      Size      Duration
1   vendor.chunk.js          script    320KB     480ms
2   main.js                  script    250KB     320ms
3   hero-image.webp          img       180KB     280ms
4   analytics.js             script    45KB      250ms    ← third-party
5   fonts/inter-var.woff2    font      95KB      180ms
...

RECOMMENDATIONS:
- vendor.chunk.js: Consider code-splitting — 320KB is large for initial load
- analytics.js: Load async/defer — blocks rendering for 250ms
- hero-image.webp: Add width/height to prevent CLS, consider lazy loading
```

### Phase 7: Performance Budget

Check against industry budgets:

```
PERFORMANCE BUDGET CHECK
════════════════════════
Metric              Budget      Actual      Status
────────            ──────      ──────      ──────
FCP                 < 1.8s      0.48s       PASS
LCP                 < 2.5s      1.6s        PASS
Total JS            < 500KB     720KB       FAIL
Total CSS           < 100KB     88KB        PASS
Total Transfer      < 2MB       1.8MB       WARNING (90%)
HTTP Requests       < 50        58          FAIL

Grade: B (4/6 passing)
```

### Phase 8: Trend Analysis (--trend mode)

Load historical baseline files and show trends:

```
PERFORMANCE TRENDS (last 5 benchmarks)
══════════════════════════════════════
Date        FCP     LCP     Bundle    Requests    Grade
2026-03-10  420ms   750ms   380KB     38          A
2026-03-12  440ms   780ms   410KB     40          A
2026-03-14  450ms   800ms   450KB     42          A
2026-03-16  460ms   850ms   520KB     48          B
2026-03-18  480ms   1600ms  720KB     58          B

TREND: Performance degrading. LCP doubled in 8 days.
       JS bundle growing 50KB/week. Investigate.
```

### Phase 9: Save Report

Write to `.gstack/benchmark-reports/{date}-benchmark.md` and `.gstack/benchmark-reports/{date}-benchmark.json`.

## Important Rules

- **Measure, don't guess.** Use actual performance.getEntries() data, not estimates.
- **Baseline is essential.** Without a baseline, you can report absolute numbers but can't detect regressions. Always encourage baseline capture.
- **Relative thresholds, not absolute.** 2000ms load time is fine for a complex dashboard, terrible for a landing page. Compare against YOUR baseline.
- **Third-party scripts are context.** Flag them, but the user can't fix Google Analytics being slow. Focus recommendations on first-party resources.
- **Bundle size is the leading indicator.** Load time varies with network. Bundle size is deterministic. Track it religiously.
- **Read-only.** Produce the report. Don't modify code unless explicitly asked.
