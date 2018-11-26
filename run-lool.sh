#!/bin/bash -xe
# This file is part of the LibreOffice project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

export LC_CTYPE=en_US.UTF-8

ETC_DIR=/etc/libreoffice-online/


## Dynamique Configuration
#    environment:
#      LOOL_DOMAIN: my-server\\.domain\\.me
#      LOOL_USERNAME: lool_admin
#      LOOL_PASSWORD: lool_password

sed -i "s,localhost</host>,${LOOL_DOMAIN}</host>,g" ${ETC_DIR}/loolwsd.xml
sed -i "s,<username .*></username>,<username>${LOOL_USERNAME}</username>," ${ETC_DIR}/loolwsd.xml
sed -i "s,<password .*></password>,<password>${LOOL_PASSWORD}</password>,g" ${ETC_DIR}/loolwsd.xml

sed -i "s,true</seccomp>,false</seccomp>,g" ${ETC_DIR}/loolwsd.xml
sed -i "s,localhost:9042/foo</monitor>,loolmonitor:8765</monitor>,g" ${ETC_DIR}/loolwsd.xml

sed -i 's,/etc/loolwsd,/etc/libreoffice-online,' ${ETC_DIR}/loolwsd.xml

## Generate Cert
/generateSSL.sh

## Start loolwsd
LOOL_PARAM="--version"
LOOL_PARAM="${LOOL_PARAM} "
LOOL_PARAM="${LOOL_PARAM} --o:sys_template_path=/opt/lool/systemplate "
LOOL_PARAM="${LOOL_PARAM} --o:lo_template_path=/opt/libreoffice "
LOOL_PARAM="${LOOL_PARAM} --o:child_root_path=/opt/lool/child-roots "
LOOL_PARAM="${LOOL_PARAM} --o:file_server_root_path=/usr/share/libreoffice-online "
#export FONTCONFIG_FILE=/etc/fonts/fonts.conf
#export FONTCONFIG_PATH=/etc/fonts/

exec /usr/bin/loolwsd ${LOOL_PARAM}
