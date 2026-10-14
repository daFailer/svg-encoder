#!/usr/bin/env bash
# Fixture checks for svg-encoder GHCR keep-all cleanup and preview teardown.
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
prune="$root/scripts/ci/prune-ghcr-release-versions.sh"
delete_pr="$root/scripts/ci/delete-preview-package-versions.sh"
delete_orphans="$root/scripts/ci/delete-orphaned-preview-packages.sh"
fixtures="$root/tests/fixtures"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

expect_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "missing ${needle@Q} in"$'\n'"$haystack"
}

expect_missing() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" != *"$needle"* ]] || fail "unexpected ${needle@Q} in"$'\n'"$haystack"
}

keep_out="$(bash "$prune" svg-encoder --from-json "$fixtures/ghcr-keep-all.json")"
expect_contains "$keep_out" "keep id=60 tags=0.6.0,latest"
expect_contains "$keep_out" "keep id=10 tags=0.1.0"
expect_contains "$keep_out" "keep id=70 tags=buildcache"
expect_contains "$keep_out" "delete id=99 tags="
expect_missing "$keep_out" "id=88"

sha_out="$(bash "$prune" svg-encoder --from-json "$fixtures/ghcr-sha-only.json")"
expect_contains "$sha_out" "delete id=6 tags=sha-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
expect_missing "$sha_out" "keep id="

pr12_out="$(bash "$delete_pr" 12 --from-json "$fixtures/ghcr-preview-versions.json")"
expect_contains "$pr12_out" "delete id=22 prefix=pr-12-"
expect_missing "$pr12_out" "id=12"

keep_current="$(bash "$delete_pr" 12 --keep-current --from-json "$fixtures/ghcr-preview-versions.json")"
expect_missing "$keep_current" "id=22"
expect_missing "$keep_current" "id=23"

orphan_out="$(bash "$delete_orphans" 12 --from-json "$fixtures/ghcr-preview-versions.json")"
expect_contains "$orphan_out" "delete id=99 orphaned-preview"
expect_missing "$orphan_out" "id=22"

yaml="$(cat "$root/.woodpecker/preview.yaml")"
expect_contains "$yaml" 'tags: pr-${CI_COMMIT_PULL_REQUEST}'
expect_missing "$yaml" 'pr-${CI_COMMIT_PULL_REQUEST}-${CI_COMMIT_SHA}'

build_yaml="$(cat "$root/.woodpecker/build.yaml")"
expect_contains "$build_yaml" 'ghcr.io/dafailer/svg-encoder:latest'
expect_missing "$build_yaml" 'sha-${CI_COMMIT_SHA}'

if bash "$prune" chargeworth-app --from-json "$fixtures/ghcr-empty.json" >/dev/null 2>&1; then
  fail "expected non-zero exit for a package name outside the allowlist"
fi

echo "ok"
