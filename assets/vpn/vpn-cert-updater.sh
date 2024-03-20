#!/bin/sh

# outside, call docker
if command -v docker >/dev/null 2>&1; then
  exec docker run --rm \
    --name=vpn-cert-updater \
    --net=none \
    -v "$(realpath "$0")":/update.sh:ro \
    -v vpn-certs:/vpn-certs \
    -v /etc/ssl/private:/ssl-certs:ro \
    alpine \
    /update.sh
  exit 1 # exec failed
fi

set -eux

SSL_CERTS="/ssl-certs"
VPN_CERTS="/vpn-certs"

cp -p "${SSL_CERTS}/lugvpn/fullchain.pem" "${VPN_CERTS}/certs/vpn.ustclug.org.crt"
cp -p "${SSL_CERTS}/lugvpn/privkey.pem" "${VPN_CERTS}/private/vpn.ustclug.org.key"
echo "Cert Update Complete"
