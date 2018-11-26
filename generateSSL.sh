#!/bin/bash -e
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

export LC_CTYPE=en_US.UTF-8
ETC_DIR=/etc/libreoffice-online

if [ ! -f "/etc/libreoffice-online/key.pem" ]
then
	# Generate new SSL certificate instead of using the default
	mkdir -p /opt/lool/ssl/certs/{ca,servers,tmp}
	cd /opt/lool/ssl/
	openssl genrsa -out certs/ca/root.key.pem 2048
	openssl req -x509 -new -nodes \
		-key certs/ca/root.key.pem \
		-days 9131 \
		-out certs/ca/root.crt.pem \
		-subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=Dummy Authority"

	mkdir -p certs/servers/localhost
	openssl genrsa -out certs/servers/localhost/privkey.pem 2048
	openssl req \
		-key certs/servers/localhost/privkey.pem \
		-new \
		-sha256 \
		-out certs/tmp/localhost.csr.pem \
		-subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=localhost"
	openssl x509 -req \
		-in certs/tmp/localhost.csr.pem \
		-CA certs/ca/root.crt.pem \
		-CAkey certs/ca/root.key.pem \
		-CAcreateserial \
		-out certs/servers/localhost/cert.pem \
		-days 9131

	mv certs/servers/localhost/privkey.pem ${ETC_DIR}/key.pem
	mv certs/servers/localhost/cert.pem ${ETC_DIR}/cert.pem
	mv certs/ca/root.crt.pem ${ETC_DIR}/ca-chain.cert.pem
fi
