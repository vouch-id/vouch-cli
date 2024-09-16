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

serviceUrl=${ARGS[0]:-}
caKeyFile=${ARGS[1]:-}
machinePublicKey=${ARGS[2]:-}
validPrincipals="${ARGS[3]:-$(id -un)}"

if [ -z "$serviceUrl" ]; then echo "Missing serviceUrl"; exit 1; fi
if [ -z "$caKeyFile" ]; then echo "Missing caKeyFile"; exit 1; fi
if [ -z "$machinePublicKey" ]; then echo "Missing machinePublicKey"; exit 1; fi

# For simplicity, this script hardcodes
#  - certificate validity: one day (24h)
#  - key identifier: takes it from the machine public key

keyId="$(echo "$machinePublicKey" | cut -d' ' -f3-)"

tmpPubKeyFile="tmpKey$$.pub"
tmpCertFile="tmpKey$$-cert.pub"
echo "$machinePublicKey" > $tmpPubKeyFile

ssh-keygen -s "$caKeyFile" -I "$keyId" -n "$validPrincipals" -V +1d "$tmpPubKeyFile"
certificate="$(cat "$tmpCertFile")"
rm -f "$tmpPubKeyFile" "$tmpCertFile"

# ^ Certificate has been issued! Now send it to the relay.

reqId="$(dd if=/dev/urandom bs=32 count=1 status=none | base64)"
req='{"jsonrpc":"2.0","id":"'"$reqId"'","method":"setCertificate","params":{"machine":"'"$machinePublicKey"'","certificate":"'"$certificate"'"}}'

stamp="$(date +%s)"
sig="$(printf "SSH $reqId $stamp %s" "$req" | ssh-keygen -q -Y sign -f "$caKeyFile" -n "api@vouch.id" - | tr -d '\n')"

${curl} -s --data-binary "$req" \
        -H "Authorization: SSH $reqId $stamp $sig" \
        -H "Content-Type: application/json" \
        "$serviceUrl"
