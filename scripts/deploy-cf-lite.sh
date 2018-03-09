#!/bin/bash
set -euo pipefail

cf_deployment=~/workspace/cf-deployment
deployment_dir="${HOME}/workspace/deployments/cf-lite" && mkdir -p "$deployment_dir"

# STEMCELL_VERSION=$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path /stemcells/alias=default/version)
# bosh ss --json|grep "$STEMCELL_VERSION" || bosh upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v="$STEMCELL_VERSION"
# bosh -n update-cloud-config "$cf_deployment"/iaas-support/bosh-lite/cloud-config.yml

bosh -n -d cf deploy --no-redact \
  --vars-store "${deployment_dir}/cf-vars.yml" \
  -o "$cf_deployment"/operations/bosh-lite.yml \
  -o "$cf_deployment"/operations/use-compiled-releases.yml \
  -o "$cf_deployment"/operations/scale-to-one-az.yml \
  -v system_domain="bosh-lite.com" \
  -o ops/disable-cf-networking.ops.yml \
  -o ops/enable-cf-extended-networking.ops.yml \
  -o ops/local-release.ops.yml \
  "$@" \
  "$cf_deployment"/cf-deployment.yml

  export CF_TARGET=https://api.bosh-lite.com
  export CF_EMAIL=admin
  export CF_PASSWORD=$(bosh int "${deployment_dir}/cf-vars.yml" --path /cf_admin_password)

echo "cf login -a  ${CF_TARGET} -u ${CF_EMAIL} -p ${CF_PASSWORD} --skip-ssl-validation"
echo "cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s"
echo "cf enable-feature-flag diego_docker"
echo "cf push test-app -o cloudfoundry/test-app -i 2"
