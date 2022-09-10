#!/bin/bash

set -eu

ARGS=()
curl=curl

while [[ $# -gt 0 ]]
do
    case $1 in
        --insecure) curl="curl -k"; shift;;
        -*|--*) echo "Unknown argument $1"; exit 1;;
        *) ARGS+=("$1"); shift;;
    esac
done

serviceUrl=${ARGS[0]}
principal=${ARGS[1]}

if [ -z "$serviceUrl" ]; then echo "Missing serviceUrl"; exit 1; fi
if [ -z "$principal" ]; then echo "Missing principal"; exit 1; fi

reqId="$(dd if=/dev/urandom bs=32 count=1 status=none | base64)"
req='{"jsonrpc":"2.0","id":"'"$reqId"'","method":"registerServer","params":{"principal":{"id":"'"$principal"'","epoch":false}}}'

${curl} -s --data-binary "$req" \
        -H "Content-Type: application/json" \
        "$serviceUrl" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["principal_key"] or "")'
