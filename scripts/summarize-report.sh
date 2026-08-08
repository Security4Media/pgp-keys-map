#!/usr/bin/env bash
# Summarizes an OWASP dependency-check JSON report into a Markdown table. Shared by the
# PR-sticky-comment step (comment-on-pr.sh) and the job summary in security-scan.*.yml.tmpl, so
# the table format only lives in one place.
#
# Env:
#   REPORT_JSON  - path to dependency-check-report.json (default: target/dependency-check-report.json)
#   SUMMARY_FILE - path to also write the Markdown summary to, for a later step to read
#                  (default: ${RUNNER_TEMP:-/tmp}/dependency-check-summary.md)
#
# Always appends the same Markdown to $GITHUB_STEP_SUMMARY (if set - i.e. running under GitHub
# Actions; skipped otherwise so this script stays runnable locally for debugging).
#
# Writes to $GITHUB_OUTPUT (if set):
#   has_vulnerabilities - "true" or "false"
#   vulnerability_count  - total number of vulnerability findings, any severity (0 when the
#                          report is missing - that failure is already surfaced via
#                          has_vulnerabilities and the warning body below, a separate concern
#                          from "how many findings")
#   summary_file         - the path the summary was written to (consumed by comment-on-pr.sh)
set -euo pipefail

report_json="${REPORT_JSON:-target/dependency-check-report.json}"
summary_file="${SUMMARY_FILE:-${RUNNER_TEMP:-/tmp}/dependency-check-summary.md}"

if [ ! -f "$report_json" ]; then
  has_vulnerabilities=true
  vulnerability_count=0
  body=$(
    echo "## OWASP dependency-check"
    echo ""
    echo ":warning: No report was found at \`$report_json\` - the scan may have failed before completing."
  )
else
  # One row per (dependency, vulnerability) pair. `.name` on a dependency-check vulnerability
  # entry is its CVE/advisory id (e.g. CVE-2023-35116); CVSS score prefers v3's baseScore,
  # falling back to v2's score, then "n/a" if dependency-check couldn't score it at all.
  rows=$(jq -r '
    [.dependencies[]? | select(.vulnerabilities) | . as $dep | $dep.vulnerabilities[] |
      "| " + ($dep.fileName // "unknown") + " | " + .name + " | " + (.severity // "UNKNOWN") + " | " +
      ((.cvssv3.baseScore // .cvssv2.score // "n/a") | tostring) + " |"
    ] | .[]
  ' "$report_json")

  if [ -z "$rows" ]; then
    has_vulnerabilities=false
    vulnerability_count=0
    body=$(
      echo "## OWASP dependency-check"
      echo ""
      echo ":white_check_mark: No known vulnerabilities detected."
    )
  else
    has_vulnerabilities=true
    vulnerability_count=$(echo "$rows" | wc -l | tr -d ' ')
    body=$(
      echo "## OWASP dependency-check"
      echo ""
      echo ":rotating_light: **$vulnerability_count** vulnerability finding(s):"
      echo ""
      echo "| Dependency | CVE | Severity | CVSS |"
      echo "| --- | --- | --- | --- |"
      echo "$rows"
      echo ""
      echo "See the uploaded \`dependency-check-report\` artifact (HTML/SARIF/JSON) for full details."
    )
  fi
fi

mkdir -p "$(dirname "$summary_file")"
echo "$body" > "$summary_file"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "$body" >> "$GITHUB_STEP_SUMMARY"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "has_vulnerabilities=$has_vulnerabilities"
    echo "vulnerability_count=$vulnerability_count"
    echo "summary_file=$summary_file"
  } >> "$GITHUB_OUTPUT"
fi

echo "$body"
