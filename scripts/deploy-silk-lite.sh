#!/bin/bash
set -euo pipefail
cf_deployment=~/workspace/cf-deployment
if [ ! -d "$cf_deployment" ]; then
  echo "try: git clone https://github.com/cloudfoundry/cf.git ~/workspace/cf-deployment"
  exit 1
fi

deployment_dir="~/workspace/deployments/bosh-lite/silk"
mkdir -p "$deployment_dir"

STEMCELL_VERSION=$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path /stemcells/alias=default/version)
bosh ss --json|grep "$STEMCELL_VERSION" || bosh upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v="$STEMCELL_VERSION"

bosh -n update-cloud-config ops/cloud-config-lite.yml

bosh -n -d silk-lite deploy \
  --vars-store "$deployment_dir/vars.yml" \
  -l bosh-lite/vars.yml \
  -o ops/use-compiled-releases.yml \
  -o ops/dns-aliases.yml \
  -o ops/enable-cf-extended-networking.ops.yml \
  -o ops/local-release.ops.yml \
  "$@" \
  bosh-lite/silk.yml
