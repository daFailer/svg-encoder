#!/usr/bin/env bash
# Create or inactivate a transient GitHub deployment for a feature preview.
# usage:
#   github-preview-deployment.sh create <app> <pr> <sha>   # reads platform-deploy stdout on stdin
#   github-preview-deployment.sh inactive <app> <pr>
#   github-preview-deployment.sh check-url <app> <url>
set -Eeuo pipefail

preview_url_re() {
  case "$1" in
    chargeworth) printf '%s' '^https://chargeworth-f[1-4]\.lab\.michaelvogtherr\.de$' ;;
    watchever) printf '%s' '^https://watchever-f[1-4]\.lab\.michaelvogtherr\.de$' ;;
    svg-encoder) printf '%s' '^https://svg-encoder-f[1-4]\.lab\.michaelvogtherr\.de$' ;;
    *) return 1 ;;
  esac
}

cmd="${1:?usage: github-preview-deployment.sh create|inactive|check-url …}"
app="${2:?}"
re="$(preview_url_re "$app")"

case "$cmd" in
  check-url)
    url="${3:?}"
    [[ "$url" =~ $re ]]
    exit 0
    ;;
  create)
    pr="${3:?}"
    sha="${4:?}"
    [[ "$pr" =~ ^[1-9][0-9]*$ ]]
    [[ "$sha" =~ ^[0-9a-f]{40}$ ]]
    : "${GHCR_TOKEN:?}" "${CI_REPO:?}"
    api="https://api.github.com/repos/${CI_REPO}"
    environment="${app}-pr-${pr}"
    payload="$(jq -cn \
      --arg ref "$sha" \
      --arg environment "$environment" \
      '{ref:$ref,environment:$environment,auto_merge:false,required_contexts:[],transient_environment:true,production_environment:false}')"
    response="$(curl --fail --silent --show-error \
      --request POST \
      -H "Authorization: Bearer $GHCR_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$api/deployments" \
      --data "$payload")"
    id="$(jq -er '.id' <<<"$response")"
    feature_url=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '%s\n' "$line"
      case "$line" in
        feature_url=https://*) feature_url="${line#feature_url=}" ;;
      esac
    done
    if [[ ! "$feature_url" =~ $re ]]; then
      feature_url=""
    fi
    if [[ -n "$feature_url" ]]; then
      state=success
      description='Preview is ready.'
      result=0
    else
      state=failure
      description='Preview deployment failed or feature_url was missing or invalid.'
      result=1
    fi
    status_payload="$(jq -cn \
      --arg state "$state" \
      --arg url "$feature_url" \
      --arg log_url "${CI_PIPELINE_URL:-}" \
      --arg description "$description" \
      '{
        state: $state,
        description: $description,
        auto_inactive: false
      } + (if $log_url == "" then {} else {log_url: $log_url} end)
        + (if $url == "" then {} else {environment_url: $url} end)')"
    curl --fail --silent --show-error \
      --request POST \
      -H "Authorization: Bearer $GHCR_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$api/deployments/${id}/statuses" \
      --data "$status_payload" >/dev/null
    exit "$result"
    ;;
  inactive)
    pr="${3:?}"
    [[ "$pr" =~ ^[1-9][0-9]*$ ]]
    : "${GHCR_TOKEN:?}" "${CI_REPO:?}"
    api="https://api.github.com/repos/${CI_REPO}"
    environment="${app}-pr-${pr}"
    deployment_id="$(curl --fail --silent --show-error \
      -H "Authorization: Bearer $GHCR_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$api/deployments?environment=${environment}&per_page=1" \
      | jq -r '.[0].id // empty')"
    [[ -z "$deployment_id" ]] && exit 0
    curl --fail --silent --show-error \
      --request POST \
      -H "Authorization: Bearer $GHCR_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$api/deployments/${deployment_id}/statuses" \
      --data '{"state":"inactive","description":"Preview resources removed.","auto_inactive":false}' \
      >/dev/null
    ;;
  *)
    echo "usage: github-preview-deployment.sh create|inactive|check-url …" >&2
    exit 1
    ;;
esac
