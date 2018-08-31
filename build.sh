#!/bin/bash -xe
export VERSION=$(egrep -o '([0-9.-]+)' /opt/online/debian/changelog | head -1)

CONFIG_OPTIONS="--enable-silent-rules --prefix=/usr --localstatedir=/var --sysconfdir=/etc"
CONFIG_OPTIONS="${CONFIG_OPTIONS} --with-lokit-path=/opt/online/bundled/include"
#--with-lokit-path="$BUILDDIR"/libreoffice/include
#--with-lo-path="$INSTDIR"/opt/libreoffice


./autogen.sh
./configure $CONFIG_OPTIONS
( cd loleaflet/po && ../../scripts/downloadpootle.sh )

make

DESTDIR="$INSTDIR" make install
