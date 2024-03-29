#!/bin/bash
source $(realpath $(dirname $0))/common.inc.sh

nonloopback="$(hostname -I | awk '{print $1}')"

docker rm -f nginx >/dev/null 2>&1 || true

CURL="curl -fsSL"
set -x

docker run -d --name=nginx -p 8080:80 nginx:alpine
sleep 2
$CURL "http://127.0.0.1:8080"
$CURL "http://${nonloopback}:8080"
docker rm -f nginx

docker run -d --name=nginx -p 127.0.0.1:8080:80 nginx:alpine
sleep 2
$CURL "http://127.0.0.1:8080"
$CURL "http://${nonloopback}:8080" && ( ERROR "should fail"; exit 1 )
docker rm -f nginx

# port driver "implicit" does not support binding on a non-loopback address:
# "Error starting userland proxy: listen tcp4 172.18.0.2:8080: bind: cannot assign requested address."
if [ "$DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER" != "implicit" ]; then
	docker run -d --name=nginx -p "${nonloopback}:8080:80" nginx:alpine
	sleep 2
	$CURL "http://127.0.0.1:8080" && ( ERROR "should fail"; exit 1 )
	$CURL "http://${nonloopback}:8080"
	docker rm -f nginx
fi

INFO "===== PASSING ====="
