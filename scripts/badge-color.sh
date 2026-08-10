#!/usr/bin/env bash
# Picks a Shields.io badge color for a value, printing the color name to stdout. Shared by
# every README badge-update step in code-quality's workflow templates that needs a red/green
# decision, so that logic lives in one place instead of being duplicated as an inline
# if/awk block per badge.
#
# Env:
#   MODE      - "zero" (green only if VALUE is exactly 0 - used for PMD/SpotBugs finding
#               counts) or "min" (green only if VALUE >= THRESHOLD - used for the coverage
#               percentage)
#   VALUE     - the number being evaluated (e.g. a finding count or a coverage percentage)
#   THRESHOLD - required only for MODE=min
set -euo pipefail

case "$MODE" in
  zero)
    if [ "$VALUE" -eq 0 ]; then echo brightgreen; else echo red; fi
    ;;
  min)
    if awk -v v="$VALUE" -v t="$THRESHOLD" 'BEGIN { exit !(v >= t) }'; then echo brightgreen; else echo red; fi
    ;;
  *)
    echo "Unknown MODE: $MODE (expected zero or min)" >&2
    exit 1
    ;;
esac
