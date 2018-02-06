#!/bin/bash
set -euo pipefail
cf_deployment=~/workspace/cf-deployment
if [ ! -d "$cf_deployment" ]; then
  echo "try: git clone https://github.com/cloudfoundry/cf.git ~/workspace/cf-deployment"
  exit 1
fi

DEPLOYMENT_DIR=${DEPLOYMENT_DIR:-deployments/cf}
mkdir -p "${DEPLOYMENT_DIR}"


bosh -n -d cf deploy --no-redact \
  --vars-store "${DEPLOYMENT_DIR}/cf-vars.yml" \
  -o "$cf_deployment"/operations/use-compiled-releases.yml \
  -o "$cf_deployment"/operations/scale-to-one-az.yml \
  -o "$cf_deployment"/operations/experimental/use-bosh-dns.yml \
  -o ops/disable-cf-networking.ops.yml \
  -o ops/enable-cf-extended-networking.ops.yml \
  -o ops/local-release.ops.yml \
  -v system_domain="cf.karampok.me" \
  "$@" \
  "$cf_deployment"/cf-deployment.yml


  #-o ops/disable-cf-networking.ops.yml \
  #-o ops/enable-cf-extended-networking.ops.yml \
  #-o ops/local-release.ops.yml \
  #-o ~/workspace/cf-deployment/operations/experimental/use-bosh-dns-for-containers.yml \
  # -o ~/workspace/service-discovery-release/opsfiles/opsfile.yml \

