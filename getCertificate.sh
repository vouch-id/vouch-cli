#!/bin/bash

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
keyFile=${ARGS[1]}
principal=${ARGS[2]}

if [ -z "$serviceUrl" ]; then echo "Missing serviceUrl"; exit 1; fi
if [ -z "$keyFile" ]; then echo "Missing keyFile"; exit 1; fi
if [ -z "$principal" ]; then echo "Missing principal"; exit 1; fi

reqId="$(dd if=/dev/urandom bs=32 count=1 status=none | base64)"
req='{"jsonrpc":"2.0","id":"'"$reqId"'","method":"getCertificate","params":{"principal":"'"$principal"'"}}'

stamp="$(date +%s)"
sig="$(printf "SSH $reqId $stamp %s" "$req" | ssh-keygen -q -Y sign -f "$keyFile" -n "ssh-cert-auth+api@leastfixedpoint.com" - | tr -d '\n')"

${curl} -v --data-binary "$req" -H "Authorization: SSH $reqId $stamp $sig" -H "Content-Type: application/json" "$serviceUrl"
