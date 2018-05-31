#!/bin/bash -xe
# This file is part of the LibreOffice project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

export LC_CTYPE=en_US.UTF-8

# Fix lool resolv.conf problem (wizdude)
rm /opt/lool/systemplate/etc/resolv.conf
ln -s /etc/resolv.conf /opt/lool/systemplate/etc/resolv.conf

if test "${DONT_GEN_SSL_CERT-set}" == set; then
# Generate new SSL certificate instead of using the default
mkdir -p /opt/ssl/
cd /opt/ssl/
mkdir -p certs/ca
openssl genrsa -out certs/ca/root.key.pem 2048
openssl req -x509 -new -nodes -key certs/ca/root.key.pem -days 9131 -out certs/ca/root.crt.pem -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=Dummy Authority"
mkdir -p certs/{servers,tmp}
mkdir -p "certs/servers/localhost"
openssl genrsa -out "certs/servers/localhost/privkey.pem" 2048 -key "certs/servers/localhost/privkey.pem"
openssl req -key "certs/servers/localhost/privkey.pem" -new -sha256 -out "certs/tmp/localhost.csr.pem" -subj "/C=DE/ST=BW/L=Stuttgart/O=Dummy Authority/CN=localhost"
openssl x509 -req -in certs/tmp/localhost.csr.pem -CA certs/ca/root.crt.pem -CAkey certs/ca/root.key.pem -CAcreateserial -out certs/servers/localhost/cert.pem -days 9131
mv certs/servers/localhost/privkey.pem /etc/loolwsd/key.pem
mv certs/servers/localhost/cert.pem /etc/loolwsd/cert.pem
mv certs/ca/root.crt.pem /etc/loolwsd/ca-chain.cert.pem
fi

chown lool -R /etc/loolwsd

# Replace trusted host
perl -pi -e "s/localhost<\/host>/${domain}<\/host>/g" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/<username desc=\"The username of the admin console. Must be set.\"><\/username>/<username desc=\"The username of the admin console. Must be set.\">${username}<\/username>/" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/<password desc=\"The password of the admin console. Must be set.\"><\/password>/<password desc=\"The password of the admin console. Must be set.\">${password}<\/password>/g" /etc/loolwsd/loolwsd.xml

perl -pi -e "s/true<\/seccomp>/false<\/seccomp>/g" /etc/loolwsd/loolwsd.xml
perl -pi -e "s/localhost:9042\/foo<\/monitor>/loolmonitor:8765<\/monitor>/g" /etc/loolwsd/loolwsd.xml

#rm -rf /usr/lib/python3.6/venv/


# Start loolwsd
LOOL_PARAM="--version"
LOOL_PARAM="${LOOL_PARAM} "
LOOL_PARAM="${LOOL_PARAM} --o:sys_template_path=/opt/lool/systemplate "
LOOL_PARAM="${LOOL_PARAM} --o:lo_template_path=/opt/libreofficedev6.1 "
LOOL_PARAM="${LOOL_PARAM} --o:child_root_path=/opt/lool/child-roots "
LOOL_PARAM="${LOOL_PARAM} --o:file_server_root_path=/usr/share/loolwsd "
#export FONTCONFIG_FILE=/etc/fonts/fonts.conf
#export FONTCONFIG_PATH=/etc/fonts/
su -c "/usr/bin/loolwsd ${LOOL_PARAM}" -s /bin/bash lool

#apt-get install python3-virtualenv
