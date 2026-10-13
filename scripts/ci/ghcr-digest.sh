#!/usr/bin/env bash
# Print registry/name@sha256:… for a GHCR repository and tag.
set -Eeuo pipefail

repo="${1:?usage: ghcr-digest.sh <repository> <tag>}"
tag="${2:?usage: ghcr-digest.sh <repository> <tag>}"
digest="$(skopeo inspect --format '{{.Digest}}' "docker://${repo}:${tag}")"
[[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]
printf '%s@%s\n' "$repo" "$digest"
