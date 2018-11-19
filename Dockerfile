###############################################################################
## BUILDING LIBRE OFFICE ONLINE
## 2 STAGES
##  - 1 - Building LibreOffice Online and dependencies (libpoco)
##  - 2 - Create runnable docker image
##
## PARAMETRES
## - ONLINE_BRANCH=master
##############################################################################

#####################
## STAGE-1 BUILD  ##
###################
FROM ubuntu as builder

ENV LOOL_GIT_REP=https://anongit.freedesktop.org/git/libreoffice/online.git \
		POCO_DEBIAN_REP=https://collaboraoffice.com/repos/Poco/ \
		NODEJS_SETUP_URL=https://deb.nodesource.com/setup_8.x \
		ONLINE_BRANCH=libreoffice-6-1

## 1. update xenial
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
			apt-transport-https \
			curl \
			gnupg

## 2. set up 3rd party repo of Poco, dependency of loolwsd
RUN echo "deb ${POCO_DEBIAN_REP} /" > /etc/apt/sources.list.d/poco.list \
	&& apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 0C54D189F4BA284D \
	&& apt-get update \
	&& apt-get -y install \
			libpoco-dev \
	&& apt-get auto-remove -y

## 3. install Node.js
WORKDIR /opt/npm
RUN curl -sL ${NODEJS_SETUP_URL} | bash - \
		&& apt-get install -y \
				nodejs  \
		&& npm i npm@latest -g \
		&& npm install \
				uglify-js \
				exorcist \
				evol-colorpicker \
				bootstrap \
				eslint \
				browserify-css \
				d3 \
				popper.js \
		&& npm install -g jake

## 4. install build dependencies
RUN apt-get install -y \
			sudo \
			git \
			wget \
			m4 \
			automake \
			debhelper \
			dh-systemd \
			devscripts \
			pkg-config \
			python-polib \
			python-lxml \
			nodejs \
			node-jake \
			libcap-dev \
			libcap2-bin \
			libcppunit-dev \
			libexpat1-dev \
			libghc-zlib-bindings-dev \
			libghc-zlib-dev \
			libpam0g-dev \
			libpcre3-dev \
			libpng-dev \
			libsqlite3-dev \
			libssl-dev \
			libtool \
			unixodbc-dev \
			fontconfig

## 5. git clone lool
WORKDIR /opt
RUN git clone --depth 1 --branch $ONLINE_BRANCH ${LOOL_GIT_REP} online

## 6. Install PO files
WORKDIR /opt/online/loleaflet/po
RUN /opt/online/scripts/downloadpootle.sh

WORKDIR /opt/online
ENV INSTDIR="/opt/online/instdir/" \
		CONFIG_OPTIONS="--enable-silent-rules --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-lokit-path=/opt/online/bundled/include"
#--with-lokit-path="$BUILDDIR"/libreoffice/include
#--with-lo-path="$INSTDIR"/opt/libreoffice

## 7. Autogen / configure
RUN set -e \
	&& ./autogen.sh \
	&& ./configure $CONFIG_OPTIONS

## 8. Apply patches
ADD patch.sh /opt/online/
ADD patches/ /opt/online/patches/
RUN  set -e \
	&& ./patch.sh \

## 9. make && make install
RUN  set -e \
	&& make -j $(expr $(lscpu -p=CPU|tail -1) + 1) \
	&& DESTDIR="$INSTDIR" make install


#####################
## STAGE-2 RUN    ##
###################
FROM ubuntu

ENV POCO_DEBIAN_REP=https://collaboraoffice.com/repos/Poco/ \
		LO_MIRROR=http://ftp.free.fr/mirrors/documentfoundation.org \
		LO_MAJOR=6.1 \
		LO_MINOR=3 \
		LO_BUILD=2

## 1. update xenial
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
			apt-transport-https \
			curl

## 2. install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y \
			adduser \
			cpio \
			fontconfig \
			ghostscript \
			gnupg \
			libcairo2 \
			libcap2-bin \
			libcups2 \
			libdbus-glib-1-2 \
			libgl1-mesa-glx \
			libpam0g \
			libpng12-0 \
			libsm6 \
			libx11-6 \
			libxcb-render0 \
			libxcb-shm0 \
			libxinerama1 \
			libxrender1 \
			locales-all

## 3. set up 3rd party repo of Poco, dependency of loolwsd
RUN set -e \
	&& echo "deb ${POCO_DEBIAN_REP} /" >> /etc/apt/sources.list.d/poco.list \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0C54D189F4BA284D \
	&& apt-get update \
	&& apt-get install -y libpoco*60

## 4. Install Libreoffice
ENV LO_TAR_FILENAME=LibreOffice_${LO_MAJOR}.${LO_MINOR}.${LO_BUILD}_Linux_x86-64_deb.tar.gz
RUN set -xe \
	&& curl ${LO_MIRROR}/libreoffice/testing/${LO_MAJOR}.${LO_MINOR}/deb/x86_64/${LO_TAR_FILENAME} \
		-o /opt/${LO_TAR_FILENAME} \
	&& tar xzf /opt/${LO_TAR_FILENAME} -C /opt \
	&& dpkg -i /opt/LibreOffice_*/DEBS/* \
	&& rm -rf /opt/LibreOffice_* /opt/${LO_TAR_FILENAME}

## 5. copy freshly built LibreOffice master and LibreOffice Online master with latest translations
COPY --from=builder /opt/online/instdir/ /
COPY --from=builder /opt/online/instdir/ /opt/lool/systemplate/

## 6. set up LibreOffice Online (normally done by postinstall script of package)
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
			-c "loolwsd-systemplate-setup /opt/lool/systemplate /opt/libreoffice${LO_MAJOR} " \
	&& touch /var/log/loolwsd.log \
	&& chown lool /var/log/loolwsd.log

## 7. copy the shell script which can start LibreOffice Online (loolwsd)
ADD run-lool.sh /
CMD bash /run-lool.sh

EXPOSE 9980
