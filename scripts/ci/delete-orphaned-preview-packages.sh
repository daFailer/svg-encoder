#!/usr/bin/env bash
# Delete GHCR pr-* versions whose PR number is not in the open-PR list.
set -Eeuo pipefail

opens=""
package=""
plan="${PLAN:-0}"
from_json=""

usage() {
  echo "usage: $0 <open-prs-csv-or-dash> [--package svg-encoder] [--plan] [--from-json FILE]" >&2
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
      [[ -z "$opens" ]] || usage
      opens="$1"
      shift
      ;;
  esac
done

[[ -n "$opens" ]] || usage
package="${package:-svg-encoder}"
[[ "$package" == "svg-encoder" ]] || usage
[[ "$opens" == "-" || "$opens" =~ ^[1-9][0-9]*(,[1-9][0-9]*)*$ ]]
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

ids="$(jq -r --arg opens "$opens" '
  ($opens | if . == "-" or . == "" then [] else split(",") end) as $open
  | .[]
  | (.metadata.container.tags // []) as $tags
  | select(any($tags[]; test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) | not)
  | select(any(
      $tags[];
      test("^pr-[0-9]+(-|$)")
      and (capture("^pr-(?<n>[0-9]+)") as $m | (($open | index($m.n)) == null))
    ))
  | .id
' <<<"$versions")"

deleted=0
while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  [[ "$id" =~ ^[0-9]+$ ]]
  echo "delete id=$id orphaned-preview"
  [[ "$plan" == "1" ]] && continue
  owner="${GITHUB_REPOSITORY_OWNER:?}"
  delete_err="$(mktemp)"
  if ! gh api -X DELETE \
    "/users/${owner}/packages/container/${package}/versions/${id}" \
    >/dev/null 2>"$delete_err"; then
    cat "$delete_err" >&2
    if is_http_forbidden_or_missing "$delete_err"; then
      rm -f -- "$delete_err"
      echo "Package Admin für Actions fehlt (Issue-Schritt 0)" >&2
      echo "skipping delete of package version ${id}; token needs delete:packages" >&2
      continue
    fi
    rm -f -- "$delete_err"
    exit 1
  fi
  rm -f -- "$delete_err"
  deleted=$((deleted + 1))
done <<<"$ids"

if [[ "$plan" == "1" ]]; then
  echo "plan complete for orphaned ${package} preview versions"
else
  echo "Deleted ${deleted} orphaned ${package} preview package version(s)."
fi
