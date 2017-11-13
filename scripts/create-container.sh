#!/bin/bash

set -eu

space_id="test-space-id"
app_id="test-app-id"
garden_server="10.244.0.2:7777"
container_handle=""

while getopts "t:s:a:h:" opt; do
    case ${opt} in
        t)
            garden_server=$OPTARG
            ;;
        s)
            space_id=$OPTARG
            ;;
        a)
            app_id=$OPTARG
            ;;
        h)
            container_handle=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

if [ -z ${container_handle} ]; then
    echo "container handle (-h) is a required argument"
    exit 1
fi

curl -X POST -H 'content-type: application/json' http://${garden_server}/containers -d@- <<container_json_end
{
  "Handle": "${container_handle}",
    "Properties": {
        "network.space_id": "${space_id}",
        "network.app_id": "${app_id}"
    },
    "netin":[{
      "host_port": 61000,
      "container_port": 8080
     }
  ]
}
container_json_end
