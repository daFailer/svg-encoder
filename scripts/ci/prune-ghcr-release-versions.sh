#!/usr/bin/env bash
# Keep Semver, :latest, and buildcache. Delete sha-* and untagged leftovers.
# Preview tags pr-* stay for preview-down / reconcile.
set -Eeuo pipefail

readonly ADMIN_HINT='Package Admin für Actions fehlt (Issue-Schritt 0)'

package=""
plan="${PLAN:-0}"
from_json=""

usage() {
  echo "usage: $0 <svg-encoder> [--plan] [--from-json FILE]" >&2
  exit 1
}

fail_admin() {
  echo "$ADMIN_HINT" >&2
  exit 1
}

is_http_forbidden_or_missing() {
  grep -Eq 'HTTP 403|HTTP 404' "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      plan=1
      shift
      ;;
    --from-json)
      [[ $# -ge 2 ]] || usage
      from_json="$2"
      shift 2
      ;;
    svg-encoder)
      [[ -z "$package" ]] || usage
      package="$1"
      shift
      ;;
    *)
      usage
      ;;
  esac
done

[[ "$package" == "svg-encoder" ]] || usage
[[ "$plan" == "0" || "$plan" == "1" ]] || usage
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

# ponytail: --from-json is a fixture seam and never calls DELETE, so tests cannot
# hit live GHCR. Upgrade: a recorded HTTP mock if apply-path coverage is needed.
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

decisions="$(
  jq -r '
    def tags: (.metadata.container.tags // []);
    def has_pr: any(tags[]; test("^pr-[0-9]+(-|$)"));
    def is_untagged: (tags | length) == 0;
    def has_semver: any(tags[]; test("^[0-9]+\\.[0-9]+\\.[0-9]+$"));
    def has_latest: any(tags[]; . == "latest");
    def has_buildcache: any(tags[]; . == "buildcache");

    [
      .[]
      | . as $v
      | (
          if has_pr then "skip"
          elif has_semver or has_latest or has_buildcache then "keep"
          else "delete"
          end
        ) as $kind
      | $v + {kind: $kind, tag_csv: (tags | join(","))}
    ] as $classified
    | $classified[]
    | select(.kind != "skip")
    | if .kind == "keep" then
        "keep id=\(.id) tags=\(.tag_csv)"
      else
        "delete id=\(.id) tags=\(.tag_csv)"
      end
  ' <<<"$versions"
)" || exit 1

if [[ -z "$decisions" ]]; then
  echo "kept 0 ${package} release version(s); deleted 0"
  exit 0
fi

deleted=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  echo "$line"
  [[ "$line" == delete\ id=* ]] || continue
  [[ "$plan" == "1" ]] && continue
  id="${line#delete id=}"
  id="${id%% *}"
  [[ "$id" =~ ^[0-9]+$ ]]
  owner="${GITHUB_REPOSITORY_OWNER:?}"
  delete_err="$(mktemp)"
  if ! gh api -X DELETE \
    "/users/${owner}/packages/container/${package}/versions/${id}" \
    >/dev/null 2>"$delete_err"; then
    cat "$delete_err" >&2
    if is_http_forbidden_or_missing "$delete_err"; then
      rm -f -- "$delete_err"
      echo "$ADMIN_HINT" >&2
      echo "skipping delete of package version ${id}; token needs delete:packages" >&2
      continue
    fi
    rm -f -- "$delete_err"
    exit 1
  fi
  rm -f -- "$delete_err"
  deleted=$((deleted + 1))
done <<<"$decisions"

if [[ "$plan" == "1" ]]; then
  echo "plan complete for ${package} non-release cleanup"
else
  echo "deleted ${deleted} ${package} package version(s)"
fi
