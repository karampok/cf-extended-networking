

Deploy CF with local cf-extended-networking release
```
./scripts/deploy-cf.sh
```


```
pass=$(bosh interpolate ./deployments/cf-vars.yml --path /cf_admin_password)
cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin  $pass
cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
```

### Push just an app
```
cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin  <passwd>
cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
cf enable-feature-flag diego_docker
cf push test-app -o cloudfoundry/test-app -i 2
```

### Demo just an app

cf create-org o && cf t -o o &&
cf create-space prod
echo $(cf space prod --guid)=5000-5100
cf create-space dev
echo $(cf space dev --guid)=8000-8100
#apply config
cf t -o o -s dev
cf t -o o -s prod
