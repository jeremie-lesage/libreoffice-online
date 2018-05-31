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

#RUN apt-get install -y libreoffice

RUN apt-get install -y apt-transport-https cpio locales-all gnupg ca-certificates curl

# set up 3rd party repo of Poco, dependency of loolwsd
RUN set -e \
	&& echo "deb https://collaboraoffice.com/repos/Poco/ /" >> /etc/apt/sources.list.d/poco.list \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0C54D189F4BA284D \
	&& apt-get update \
	&& apt-get install -y libpoco*60


RUN set -xe \
	&& curl http://ftp.free.fr/mirrors/documentfoundation.org/libreoffice/testing/6.1.0/deb/x86_64/LibreOfficeDev_6.1.0.0.beta1_Linux_x86-64_deb.tar.gz -o /opt/LibreOffice_deb.tar.gz \
	&& tar xzf /opt/LibreOffice_deb.tar.gz -C /opt \
	&& dpkg -i /opt/LibreOfficeDev_*/DEBS/* \
	&& rm -rf /opt/LibreOfficeDevDev_*


RUN set -e \
	&& apt-get install -y libcap2-bin libdbus-glib-1-2 libx11-6 libcairo2 libsm6 \
		adduser fontconfig libxinerama1 libxrender1 libgl1-mesa-glx libcups2 cpio \
		libcap2-bin libxcb-render0 libxcb-shm0 libpam0g libpng12-0 libpococrypto60 \
		ghostscript libssl1.0.0

# copy freshly built LibreOffice master and LibreOffice Online master with latest translations
COPY --from=builder /opt/online/instdir/ /
COPY --from=builder /opt/online/instdir/ /opt/lool/systemplate/

#RUN curl http://ftp.free.fr/mirrors/documentfoundation.org/libreoffice/stable/5.4.7/deb/x86_64/LibreOffice_5.4.7_Linux_x86-64_deb_sdk.tar.gz -o /opt/LibreOffice_deb_sdk.tar.gz \
#	&& tar xzf /opt/LibreOffice_deb_sdk.tar.gz -C /opt \
#	&& dpkg -i /opt/LibreOffice_*_Linux_x86-64_deb_sdk/DEBS/* \
#	&& rm -rf /opt/LibreOffice_deb_sdk.tar.gz /opt/LibreOffice_*_Linux_x86-64_deb_sdk


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
			-c "loolwsd-systemplate-setup /opt/lool/systemplate /opt/libreofficedev6.1 " \
	&& touch /var/log/loolwsd.log \
	&& chown lool /var/log/loolwsd.log



# copy the shell script which can start LibreOffice Online (loolwsd)
ADD run-lool.sh /
CMD bash /run-lool.sh

EXPOSE 9980
