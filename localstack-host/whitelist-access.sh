#!/usr/bin/env bash
set -euo pipefail

IP=$(echo "${SSH_CLIENT:-}" | awk '{print $1}')

if [[ -z "$IP" ]]; then
  echo "error: \$SSH_CLIENT is empty — are you running this inside an SSH session?" >&2
  exit 1
fi

NAMESPACE="${NAMESPACE:-localstack}"
INGRESS="${INGRESS:-localstack}"

kubectl annotate ingress -n "$NAMESPACE" "$INGRESS" \
  nginx.ingress.kubernetes.io/whitelist-source-range="$IP/32" \
  --overwrite

echo "whitelisted $IP/32 on ingress $NAMESPACE/$INGRESS"
