#!/usr/bin/env bash
# Downloads and extracts the NVD database snapshot from chenhuawei/nvd-mirror into
# $HOME/dependency-check-data, verifying its sha256 against $MIRROR_DIGEST whenever available.
# Checksum verification is NOT optional here: this snapshot feeds an unofficial third-party
# artifact straight into the security scan, so an unverified download is exactly the kind of
# supply-chain gap this whole `security` group exists to close elsewhere.
#
# $HOME/dependency-check-data must stay in sync with the "Restore cached NVD database" cache
# step's `path:` and the "Analyze dependencies" step's `-DdataDirectory=` in
# security-scan.community-mirror.yml.tmpl.
#
# Env:
#   MIRROR_URL    - resolved download URL (from nvd-mirror-lookup-release.sh); if unset, falls
#                   back to the stable nvd-data-latest release URL and SKIPS checksum
#                   verification, since that only happens when the release-metadata lookup
#                   already failed (see the warning it emits)
#   MIRROR_DIGEST - expected sha256 digest (e.g. "sha256:...."); optional, see above
set -euo pipefail

data_dir="$HOME/dependency-check-data"
url="${MIRROR_URL:-}"
digest="${MIRROR_DIGEST:-}"
archive="$(mktemp -t nvd-database-XXXXXX.tar.gz)"
trap 'rm -f "$archive"' EXIT

if [ -z "$url" ]; then
  url="https://github.com/chenhuawei/nvd-mirror/releases/download/nvd-data-latest/nvd-database.tar.gz"
  echo "::warning title=NVD mirror digest unavailable::Downloading the NVD snapshot without integrity verification because the release metadata lookup failed. This should be a transient condition - investigate if it persists across runs." >&2
fi

mkdir -p "$data_dir"
curl -sfL -o "$archive" "$url"

if [ -n "$digest" ]; then
  actual="sha256:$(sha256sum "$archive" | cut -d' ' -f1)"
  if [ "$actual" != "$digest" ]; then
    echo "::error title=NVD mirror checksum mismatch::Downloaded archive digest $actual does not match expected $digest - refusing to use it." >&2
    exit 1
  fi
fi

tar -xzf "$archive" -C "$data_dir" --strip-components=1

if [ -z "$(find "$data_dir" -maxdepth 2 -name '*.mv.db' -print -quit)" ]; then
  echo "::error title=NVD mirror archive empty::No .mv.db file found after extracting the mirror archive." >&2
  exit 1
fi
