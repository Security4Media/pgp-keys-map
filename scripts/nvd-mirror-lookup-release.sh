#!/usr/bin/env bash
# Resolves chenhuawei/nvd-mirror's latest NVD database release: writes the nvd-database.tar.gz
# asset's `digest` (sha256:...) and `url` to $GITHUB_OUTPUT, for the cache step and
# nvd-mirror-download-database.sh to consume.
#
# chenhuawei/nvd-mirror is an UNOFFICIAL, third-party GitHub project (see the candid notice at
# the top of security-scan.community-mirror.yml.tmpl) - this script only ever reads its public
# release metadata, never anything requiring write access.
#
# Env:
#   GH_TOKEN - bearer token, used only to raise the GitHub API rate limit (e.g. secrets.GITHUB_TOKEN)
#
# On any failure, emits a ::warning:: and exits 1. The caller is expected to run this step with
# `continue-on-error: true` and fall back to the most recently cached NVD snapshot (if any) via
# the cache step's restore-keys - it may be stale until this is resolved, but a stale mirror
# snapshot is still far better than failing the whole scan.
set -euo pipefail

warn_and_fail() {
  echo "::warning title=NVD mirror lookup failed::$1 Falling back to the most recently cached NVD snapshot (if any) via restore-keys - it may be stale until this is resolved." >&2
  exit 1
}

gh_token="${GH_TOKEN:-}"
auth_header=()
if [ -n "$gh_token" ]; then
  auth_header=(-H "Authorization: Bearer ${gh_token}")
fi

response=$(curl -sf "${auth_header[@]}" \
  https://api.github.com/repos/chenhuawei/nvd-mirror/releases/tags/nvd-data-latest) \
  || warn_and_fail "Could not reach chenhuawei/nvd-mirror's release API."

digest=$(echo "$response" | jq -r '.assets[]? | select(.name=="nvd-database.tar.gz") | .digest // empty')
url=$(echo "$response" | jq -r '.assets[]? | select(.name=="nvd-database.tar.gz") | .browser_download_url // empty')

if [ -z "$digest" ] || [ -z "$url" ]; then
  warn_and_fail "Release response didn't contain the expected nvd-database.tar.gz asset."
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "digest=$digest"
    echo "url=$url"
  } >> "$GITHUB_OUTPUT"
fi
