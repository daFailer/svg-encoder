#!/usr/bin/env bash
# Login to GHCR and docker buildx build --platform linux/amd64 --push remaining args.
# provenance/sbom off: attestation indexes are untagged and prune-ghcr deletes them.
set -Eeuo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/ensure-docker.sh"
: "${GHCR_TOKEN:?}"
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io --username daFailer --password-stdin
exec docker buildx build --platform linux/amd64 --provenance=false --sbom=false --push "$@"
