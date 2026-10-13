#!/usr/bin/env bash
# Print a URL-encoded PR title when the pull request is eligible for preview-up.
# Exit 0 with empty stdout to skip. Exit 1 on API or validation errors.
set -Eeuo pipefail

pr="${CI_COMMIT_PULL_REQUEST:?}"
sha="${CI_COMMIT_SHA:?}"
repo="${CI_REPO:?}"
owner="${CI_REPO_OWNER:?}"
: "${GHCR_TOKEN:?}"
[[ "$pr" =~ ^[1-9][0-9]*$ ]]
[[ "$sha" =~ ^[0-9a-f]{40}$ ]]

pr_json="$(curl --fail --silent --show-error \
  -H "Authorization: Bearer $GHCR_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${repo}/pulls/${pr}")"

if ! jq -e \
  --arg sha "$sha" \
  --arg repository "$repo" \
  --arg owner "$owner" \
  '.state == "open" and .draft == false and .head.sha == $sha and .head.repo.full_name == $repository and .user.login == $owner and .user.login != "dependabot[bot]"' \
  <<<"$pr_json" >/dev/null; then
  printf 'Skipping feature preview: PR #%s is not eligible.\n' "$pr" >&2
  exit 0
fi

jq -r '(.title // "preview") | if . == "" then "preview" else . end | .[0:120] | @uri' <<<"$pr_json"
