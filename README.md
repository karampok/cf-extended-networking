

Deploy CF with local cf-extended-networking release
```
./scripts/deploy-cf.sh
```


```
pass=$(bosh interpolate ./deployments/cf-vars.yml --path /cf_admin_password)
cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin  $pass 
cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
```
