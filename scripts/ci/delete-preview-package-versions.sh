#!/usr/bin/env bash
# Delete GHCR versions tagged pr-<PR> or pr-<PR>-* that do not also carry a
# semver tag. --keep-current leaves the version currently tagged pr-<PR> and
# also drops untagged leftovers from overwriting that tag.
set -Eeuo pipefail

pr=""
package=""
plan="${PLAN:-0}"
from_json=""
keep_current=0

usage() {
  echo "usage: $0 <pr-number> [--package svg-encoder] [--keep-current] [--plan] [--from-json FILE]" >&2
  exit 1
}

fail_admin() {
  echo "Package Admin für Actions fehlt (Issue-Schritt 0)" >&2
  exit 1
}

is_http_forbidden_or_missing() {
  grep -Eq 'HTTP 403|HTTP 404' "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package)
      [[ $# -ge 2 ]] || usage
      [[ -z "$package" ]] || usage
      package="$2"
      shift 2
      ;;
    --keep-current)
      keep_current=1
      shift
      ;;
    --plan)
      plan=1
      shift
      ;;
    --from-json)
      [[ $# -ge 2 ]] || usage
      from_json="$2"
      shift 2
      ;;
    *)
      [[ -z "$pr" && "$1" =~ ^[1-9][0-9]*$ ]] || usage
      pr="$1"
      shift
      ;;
  esac
done

[[ -n "$pr" ]] || usage
package="${package:-svg-encoder}"
[[ "$package" == "svg-encoder" ]] || usage
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

if [[ -n "$from_json" ]]; then
  plan=1
  [[ -f "$from_json" ]] || { echo "versions file not found: $from_json" >&2; exit 1; }
  versions="$(jq -c -e 'if type == "array" then . else error("versions JSON must be an array") end' "$from_json")"
else
  command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
  owner="${GITHUB_REPOSITORY_OWNER:-}"
  [[ -n "$owner" ]] || { echo "GITHUB_REPOSITORY_OWNER is required" >&2; exit 1; }
  list_url="/users/${owner}/packages/container/${package}/versions"
  list_err="$(mktemp)"
  trap 'rm -f -- "$list_err"' EXIT
  if ! versions="$(
    gh api --paginate "$list_url" --jq '.[]' 2>"$list_err" | jq -c -s '.'
  )"; then
    cat "$list_err" >&2
    if is_http_forbidden_or_missing "$list_err"; then
      fail_admin
    fi
    exit 1
  fi
fi

prefix="pr-${pr}-"
exact="pr-${pr}"
ids="$(jq -r --arg prefix "$prefix" --arg exact "$exact" --argjson keep_current "$keep_current" '
  def tags: (.metadata.container.tags // []);
  def has_semver: any(tags[]; test("^[0-9]+\\.[0-9]+\\.[0-9]+$"));
  def is_pr: any(tags[]; . == $exact or startswith($prefix));
  def is_current: any(tags[]; . == $exact);
  def is_untagged: (tags | length) == 0;

  .[]
  | select(has_semver | not)
  | select(
      if $keep_current == 1 then
        (is_pr and (is_current | not)) or is_untagged
      else
        is_pr
      end
    )
  | .id
' <<<"$versions")"

deleted=0
while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  [[ "$id" =~ ^[0-9]+$ ]]
  echo "delete id=$id prefix=$prefix"
  [[ "$plan" == "1" ]] && continue
  owner="${GITHUB_REPOSITORY_OWNER:?}"
  delete_err="$(mktemp)"
  if ! gh api -X DELETE \
    "/users/${owner}/packages/container/${package}/versions/${id}" \
    >/dev/null 2>"$delete_err"; then
    cat "$delete_err" >&2
    if is_http_forbidden_or_missing "$delete_err"; then
      rm -f -- "$delete_err"
      fail_admin
    fi
    rm -f -- "$delete_err"
    exit 1
  fi
  rm -f -- "$delete_err"
  deleted=$((deleted + 1))
done <<<"$ids"

if [[ "$plan" == "1" ]]; then
  echo "plan complete for ${package} preview PR ${pr}"
else
  echo "Deleted ${deleted} ${package} package version(s) for PR ${pr}."
fi
