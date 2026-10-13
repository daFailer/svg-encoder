#!/usr/bin/env bash
# Install a pinned GitHub CLI binary when gh is missing.
set -Eeuo pipefail

gh_ver="${GH_CLI_VERSION:-2.81.0}"
if command -v gh >/dev/null 2>&1; then
  gh --version
  exit 0
fi

command -v curl >/dev/null 2>&1 || { echo "curl is required to install gh" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
archive="gh_${gh_ver}_linux_amd64"
curl --fail --location --retry 5 --retry-delay 2 \
  --output "$tmp/gh.tgz" \
  "https://github.com/cli/cli/releases/download/v${gh_ver}/${archive}.tar.gz"
tar -xzf "$tmp/gh.tgz" -C "$tmp"
install -m 0755 "$tmp/${archive}/bin/gh" /usr/local/bin/gh
gh --version
