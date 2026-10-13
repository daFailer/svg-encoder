#!/usr/bin/env bash
# Run platform-deploy over SSH. Expects DEPLOY_HOST, DEPLOY_PORT, DEPLOY_USER,
# DEPLOY_KNOWN_HOSTS, DEPLOY_SSH_KEY, EXPECTED_DEPLOY_USER.
set -Eeuo pipefail

[[ "${DEPLOY_HOST:-}" =~ ^[0-9a-fA-F:.]+$ ]]
[[ "${DEPLOY_PORT:-}" =~ ^[0-9]+$ ]]
[[ "${DEPLOY_USER:-}" == "${EXPECTED_DEPLOY_USER:-}" ]]
[[ -n "${DEPLOY_KNOWN_HOSTS:-}" && -n "${DEPLOY_SSH_KEY:-}" ]]
[[ $# -ge 1 ]]

umask 077
key_file="$(mktemp)"
known_hosts_file="$(mktemp)"
trap 'rm -f -- "$key_file" "$known_hosts_file"' EXIT
printf '%s\n' "$DEPLOY_SSH_KEY" > "$key_file"
printf '%s\n' "$DEPLOY_KNOWN_HOSTS" > "$known_hosts_file"
chmod 600 "$key_file" "$known_hosts_file"

ssh -i "$key_file" -o BatchMode=yes -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$known_hosts_file" \
  -p "$DEPLOY_PORT" "$DEPLOY_USER@$DEPLOY_HOST" \
  "platform-deploy $*"
