#!/usr/bin/env bash
set -euo pipefail

(
cd "$(dirname "$0")/.."
bosh -n update-cloud-config manifests/cloud-config-lite.yml
bosh -n -e "${BOSH_ENVIRONMENT:-lite}" -d garden-runc-net deploy --no-redact \
  -l manifests/bosh-lite.vars.yml \
  -o manifests/enable-cf-net.ops.yml \
  -o manifests/local-cf-net-release.ops.yml \
  "$@" \
  manifests/garden-runc.yml
)
