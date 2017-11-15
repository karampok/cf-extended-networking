#!/bin/bash
set -euo pipefail
cf_deployment=~/workspace/cf-deployment
if [ ! -d "$cf_deployment" ]; then
  echo "try: git clone https://github.com/cloudfoundry/cf.git ~/workspace/cf-deployment"
  exit 1
fi

director_dir=~/workspace/bosh-lite
mkdir -p "$director_dir"
deployment_dir="$director_dir/cf"
mkdir -p "$deployment_dir"

STEMCELL_VERSION=$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path /stemcells/alias=default/version)
bosh upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=$STEMCELL_VERSION
bosh -n update-cloud-config "$cf_deployment"/iaas-support/bosh-lite/cloud-config.yml
# bosh update-runtime-config -n ~//workspace/bosh-deployment/runtime-configs/dns.yml
bosh -n -d cf deploy \
  -o "$cf_deployment"/operations/bosh-lite.yml \
  -o "$cf_deployment"/operations/use-compiled-releases.yml \
  -o "$cf_deployment"/operations/scale-to-one-az.yml \
  -o "$cf_deployment"/operations/experimental/use-bosh-dns.yml \
  -o manifests/disable-cf-networking.ops.yml \
  -o manifests/enable-cf-extended-networking.ops.yml \
  -o manifests/local-cf-net-release.ops.yml \
  --vars-store "$deployment_dir/cf-vars.yml" \
  -v system_domain="bosh-lite.com" \
  "$@" \
  "$cf_deployment"/cf-deployment.yml
