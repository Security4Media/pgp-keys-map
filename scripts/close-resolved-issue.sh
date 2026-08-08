#!/usr/bin/env bash
# imjohnbo/issue-bot only ever closes the *previous* tracking issue when a *new* one is filed for
# a fresh finding - so once dependency-check goes clean again, nothing else would close the last
# open tracking issue. This closes any open issue(s) labeled $ISSUE_LABEL.
#
# The caller (security-scan.*.yml) is responsible for only invoking this step on `push`
# events with a clean scan (has_vulnerabilities == 'false') - this script does not check
# github.event_name or the scan result itself, since it has no access to workflow context, only
# the env var below.
#
# Env:
#   ISSUE_LABEL - the label used to find the dependency-check tracking issue(s)
#   GH_TOKEN    - must be set for `gh` to authenticate (e.g. secrets.GITHUB_TOKEN)
set -euo pipefail

issue_label="${ISSUE_LABEL:?ISSUE_LABEL must be set}"

gh issue list --label "$issue_label" --state open --json number --jq '.[].number' | while read -r number; do
  gh issue close "$number" \
    --comment "OWASP dependency-check found no known vulnerabilities in the latest scan of \`main\` - closing."
done
