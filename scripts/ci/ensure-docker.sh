#!/usr/bin/env bash
# Start dockerd when Woodpecker `commands:` replaced plugin-docker-buildx's entrypoint.
set -Eeuo pipefail

if docker info >/dev/null 2>&1; then
  exit 0
fi

starter=""
for candidate in dockerd-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh dockerd; do
  if command -v "$candidate" >/dev/null 2>&1; then
    starter="$candidate"
    break
  fi
  if [[ -x "$candidate" ]]; then
    starter="$candidate"
    break
  fi
done
[[ -n "$starter" ]] || {
  echo "docker daemon is not available" >&2
  exit 1
}

"$starter" >/dev/null 2>&1 &
for _ in $(seq 1 30); do
  docker info >/dev/null 2>&1 && exit 0
  sleep 1
done
docker info >/dev/null
