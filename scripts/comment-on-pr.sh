#!/usr/bin/env bash
# Posts or updates a sticky PR comment with the dependency-check summary written by
# summarize-report.sh. `--edit-last` errors out if no earlier comment from this token exists
# yet, so the fallback creates the first one - this avoids depending on the newer
# `--create-if-none` flag, which isn't reliably available on every `gh` CLI version yet.
#
# The caller (security-scan.*.yml) is responsible for only invoking this step on
# `pull_request` events - this script does not check github.event_name itself, since it has no
# access to workflow context, only the env vars below.
#
# Env:
#   PR_NUMBER    - the pull request number to comment on
#   SUMMARY_FILE - path to the Markdown summary (written by summarize-report.sh)
#   GH_TOKEN     - must be set for `gh` to authenticate (e.g. secrets.GITHUB_TOKEN)
set -euo pipefail

pr_number="${PR_NUMBER:?PR_NUMBER must be set}"
summary_file="${SUMMARY_FILE:?SUMMARY_FILE must be set}"

if [ ! -f "$summary_file" ]; then
  echo "::error title=comment-on-pr.sh::SUMMARY_FILE '$summary_file' does not exist - did summarize-report.sh run first?" >&2
  exit 1
fi

gh pr comment "$pr_number" --edit-last --body-file "$summary_file" \
  || gh pr comment "$pr_number" --body-file "$summary_file"
