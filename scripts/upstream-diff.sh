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
