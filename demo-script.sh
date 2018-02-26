

# Clean up
rm  ./jobs/cni-configs/templates/ipmasq.config

cf t -s dev && cf delete db-dev -r -f
cf t -s prod && cf delete db-prod -r -f

#cf delete-space prod -f
#cf delete-space dev -f


# Create spaces and get guids
cf create-space dev
echo $(cf space dev --guid)=8000-8100
echo $(cf space dev --guid)=8000-8100 >> ./jobs/cni-configs/templates/masqrules.config

cf create-space prod
echo $(cf space prod --guid)=5000-5100
echo $(cf space prod --guid)=5000-5100 >> ./jobs/cni-configs/templates/masqrules.config

cat ./jobs/cni-configs/templates/masqrules.config

Deploy CF with local cf-extended-networking release
```
./scripts/deploy-cf.sh
```


# Push apps

cf t -s prod && cf push db-prod -o cloudfoundry/test-app && cf ssh db-prod -c 'wget http://ipinfo.io -q -O -'
cf t -s prod && cf ssh db-prod -c 'wget http://ipinfo.io -q -O -'
cf t -s dev && cf push db-dev -o cloudfoundry/test-app && cf ssh db-dev -c 'wget http://ipinfo.io -q -O -'
cf t -s dev && cf ssh db-dev -c 'wget http://ipinfo.io -q -O -'
```
pass=$(bosh interpolate ./deployments/cf-vars.yml --path /cf_admin_password)
cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin  $pass
cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
```

### Push just an app
```
cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
cf enable-feature-flag diego_docker
cf push test-app -o cloudfoundry/test-app -i 2
```

### Demo just an app

cf create-org o && cf t -o o &&
#apply config
cf t -o o -s dev
cf t -o o -s prod

cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin  <passwd>
