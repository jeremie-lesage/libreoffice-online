#!/bin/bash -xe
VERSION=$(egrep -o '([0-9.-]+)' /opt/online/debian/changelog | head -1)
cd /opt/online
./autogen.sh

cd /opt
tar cf loolwsd_${VERSION%-*}.orig.tar online/
gzip -1 loolwsd_${VERSION%-*}.orig.tar

cd /opt/online
dpkg-buildpackage -us -uc -b -j4

cp ../*deb .
