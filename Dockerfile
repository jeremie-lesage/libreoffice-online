FROM ubuntu:xenial as builder

# get the latest fixes
RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
			libpng-dev libcap-dev libtool m4 automake fakeroot \
			debhelper dh-systemd build-essential unixodbc-dev \
			python-polib nodejs node-jake libghc-zlib-bindings-dev \
			libghc-zlib-dev git pkg-config libcppunit-dev libpam0g-dev python-lxml \
			libexpat1-dev libpcre3-dev libsqlite3-dev \
			libssl-dev devscripts libssl1.0.0 libcap2-bin fontconfig

# set up 3rd party repo of Poco, dependency of loolwsd
RUN echo "deb https://collaboraoffice.com/repos/Poco/ /" >> /etc/apt/sources.list.d/poco.list \
	&& apt-get install -y apt-transport-https \
	&& apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 0C54D189F4BA284D \
	&& apt-get update \
	&& apt-get -y install libpoco-dev \
	&& apt-get auto-remove -y

WORKDIR /opt/npm
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
		&& apt-get install -y nodejs \
		&& npm install uglify-js exorcist evol-colorpicker bootstrap eslint \
			browserify-css d3 popper.js \
		&& npm install -g jake

RUN apt-get install -y wget
RUN apt-get auto-remove -y

ARG ONLINE_BRANCH

WORKDIR /opt

RUN git clone --depth 1 --branch $ONLINE_BRANCH \
	https://anongit.freedesktop.org/git/libreoffice/online.git online

RUN pwd

WORKDIR /opt/online/loleaflet/po
RUN ls /opt/online && /opt/online/scripts/downloadpootle.sh

WORKDIR /opt/online
ENV INSTDIR="/opt/online/instdir/" \
		CONFIG_OPTIONS="--enable-silent-rules --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-lokit-path=/opt/online/bundled/include"
#--with-lokit-path="$BUILDDIR"/libreoffice/include
#--with-lo-path="$INSTDIR"/opt/libreoffice

ADD httpwstest_bug_poco.patch /opt/online/

RUN patch -p1 < httpwstest_bug_poco.patch

RUN ./autogen.sh \
		&& ./configure $CONFIG_OPTIONS \
		&& make -j 8 \
		&& DESTDIR="$INSTDIR" make install


## FINAL STAGE ##
FROM ubuntu:xenial

# get the latest fixes
RUN apt-get update && apt-get upgrade -y

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install -y libreoffice

RUN apt-get install -y apt-transport-https cpio locales-all gnupg ca-certificates curl

# set up 3rd party repo of Poco, dependency of loolwsd
RUN set -e \
	&& echo "deb https://collaboraoffice.com/repos/Poco/ /" >> /etc/apt/sources.list.d/poco.list \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0C54D189F4BA284D \
	&& apt-get update \
	&& apt-get install -y libpoco*60

# copy freshly built LibreOffice master and LibreOffice Online master with latest translations
COPY --from=builder /opt/online/instdir/ /
COPY --from=builder /opt/online/instdir/ /opt/lool/systemplate/


# set up LibreOffice Online (normally done by postinstall script of package)
RUN set -e \
	&& setcap cap_fowner,cap_mknod,cap_sys_chroot+iep /usr/bin/loolforkit \
	&& adduser --quiet --system --group --home /opt/lool lool \
	&& mkdir -p /var/cache/loolwsd \
	&& chown lool: /var/cache/loolwsd \
	&& rm -rf /var/cache/loolwsd/* \
	&& rm -rf /opt/lool \
	&& mkdir -p /opt/lool/child-roots \
	&& chown -R lool: /opt/lool \
	&& su lool --shell=/bin/sh \
			-c "loolwsd-systemplate-setup /opt/lool/systemplate /usr/lib/libreoffice " \
	&& touch /var/log/loolwsd.log \
	&& chown lool /var/log/loolwsd.log

CMD bash /run-lool.sh

EXPOSE 9980
