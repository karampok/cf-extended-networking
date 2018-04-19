#! /bin/bash

rm ./jobs/cni-configs/templates/masqrules.config
cf t -s dev && cf delete db-dev -r -f
cf t -s prod && cf delete db-prod -r -f
# cf delete-space prod -f
# cf delete-space dev -f
# cf t -o o -s s
ssh -t mysql 'sudo iptables -D DOCKER -s 34.248.88.191/32 -p tcp -m tcp --dport 3306 -j ACCEPT'

