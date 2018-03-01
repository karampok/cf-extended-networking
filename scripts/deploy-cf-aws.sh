#!/bin/bash
set -euo pipefail

cf_deployment=~/workspace/cf-deployment
DEPLOYMENT_DIR=${DEPLOYMENT_DIR:-deployments/cf} && mkdir -p "${DEPLOYMENT_DIR}"

# STEMCELL_VERSION=$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path /stemcells/alias=default/version)
# bosh ss --json|grep "$STEMCELL_VERSION" || bosh upload-stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v="$STEMCELL_VERSION"

bosh -n -d cf deploy --no-redact \
  --vars-store "${DEPLOYMENT_DIR}/cf-vars.yml" \
  -o "$cf_deployment"/operations/use-compiled-releases.yml \
  -o "$cf_deployment"/operations/scale-to-one-az.yml \
  -v system_domain="cf.karampok.me" \
  -o ops/disable-cf-networking.ops.yml \
  -o ops/enable-cf-extended-networking.ops.yml \
  -o ops/local-release.ops.yml \
  "$@" \
  "$cf_deployment"/cf-deployment.yml

  export CF_TARGET=https://api.cf.karampok.me
  export CF_EMAIL=admin
  export CF_PASSWORD=$(bosh int "${DEPLOYMENT_DIR}/cf-vars.yml" --path /cf_admin_password)

echo " cf login -a  ${CF_TARGET} -u ${CF_EMAIL} -p ${CF_PASSWORD} --skip-ssl-validation"
echo "cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s"
echo "cf enable-feature-flag diego_docker"
echo "cf push test-app -o cloudfoundry/test-app -i 2"
  #-o ops/enable-cf-extended-networking.ops.yml \
  #-o ops/local-release.ops.yml \
  #-o ~/workspace/cf-deployment/operations/experimental/use-bosh-dns-for-containers.yml \
  # -o ~/workspace/service-discovery-release/opsfiles/opsfile.yml \

