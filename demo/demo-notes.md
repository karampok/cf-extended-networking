
# 3- windows (apps,cells,mysql-server) 
and two chrome/guest bars at 67%? (ctr-shift-alt + arrow) 


# Present the setup
# I have a bosh director `bosh vms`
# and a CF deployed on that, with bbl `cf target`


cf spaces
# one name *prod*, where production apps
# one name *dev*, where development workload  will run

```
cf create-space dev
```

I save the spaces guids into a file which holds the map, SpaceGuid <-> SrcPortRange

echo $(cf space prod --guid)=5000-5100
echo $(cf space dev --guid)=8000-8100
echo $(cf space prod --guid)=5000-5100 >> ./jobs/cni-configs/templates/masqrules.config
echo $(cf space dev --guid)=8000-8100 >> ./jobs/cni-configs/templates/masqrules.config

So I have the following map
```
cat ./jobs/cni-configs/templates/masqrules.config
```



# I deploy CF with local cf-extended-networking release to include this config
./scripts/deploy-cf-aws.sh
While deploying
- show script
- show ops-file

- show binaries
- show cni-config
- show ipmasq 


cf t -o o -s prod
cf push db-prod -n db-prod  -o karampok/db-app -i 2 --no-start
cf set-env db-prod DB_URL "${DB_URL}"
cf set-env db-prod APP_NAME PROD-APP
cf start db-prod
cf t -s prod && cf ssh db-prod -c 'wget -q http://ipinfo.io -O -'
curl db-prod.cf.karampok.me

cf t -o o -s dev
cf push db-dev -n db-dev  -o karampok/db-app -i 2 --no-start
cf set-env db-dev DB_URL "${DB_URL}"
cf set-env db-dev APP_NAME DEV-APP
cf start db-dev
cf t -s dev && cf ssh db-dev -c 'wget  -q http://ipinfo.io -O -'
curl db-dev.cf.karampok.me

ssh mysql
sudo iptables -nvL DOCKER
sudo iptables -I DOCKER 1 -s 34.248.88.191/32  -p tcp --dport 3306 -j ACCEPT

#web also

cf t -s prod && cf ssh db-prod 
cf t -s dev && cf ssh db-dev 




# More Stuff

## Routing
We could control the `ip routing` part
If I log in into the prod app and do an `ip route`, I see my custom rules.
In that case a black hole that could be used for efficient firewalling.
```
cf t -s prod && cf ssh db-prod -c 'ip r'
```

## DNS registration
We do an DNS registration based on the app-guid, in the consul.
So, we could also that the containers are pinging each other because of DNS registration
So, if I go the prod app and get its ip (`ip a`)
And, I ssh to the dev app, I can do
```
cf t -s dev && cf ssh db-dev
ping xxxx.service.cf.internal
nslookup   #see two IPs
```

## Debuging


# Under the hood
Her are the binaries I am using in the chain
Here are the iptables rules
```
iptables -nvL CNI-SNAT-X -t nat
```
