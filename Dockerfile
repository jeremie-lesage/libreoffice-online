FROM fedora:29 as base

#RUN yum install epel-release &&
#		yum update -y

ENV LO_MIRROR=http://ftp.free.fr/mirrors/documentfoundation.org \
		LO_RELEASE=testing \
		LO_MAJOR=6.2 \
		LO_MINOR=0 \
		LO_BUILD=0.beta1 \
		LO_BASENAME=LibreOfficeDev

ENV LOOL_GIT_REP=https://anongit.freedesktop.org/git/libreoffice/online.git \
		ONLINE_BRANCH=libreoffice-6.2.0.0.beta1

#RUN yum install -y yum-plugin-fastestmirror

#####################
## STAGE-1 BUILD  ##
###################
FROM base as builder

## 1. Dev tools
RUN yum group install -y "Development Tools"

## 2. others build dependencies
RUN yum install -y \
			devscripts \
			fontconfig \
			gcc \
			gcc-c++ \
			libtool \
			npm \
			sudo \
			cppunit-devel \
			libcap-devel \
			libpng-devel \
			openssl-devel \
			pam-devel \
			pcre-devel \
			poco-devel \
			python3-polib

## 3. Clone LibreOffice Online
WORKDIR /opt
RUN git clone --depth 1 --branch ${ONLINE_BRANCH} ${LOOL_GIT_REP} online

## 4. Fix NPM dependency
#WORKDIR /opt/online/loleaflet
#RUN npm install \
#	&& npm update jquery --depth 2 \
#	&& npm install --save-dev browserify-css@0.14.0 \
#	&& npm install --save-dev uglify-js@3.4.9 \
#	&& npm install --save-dev uglifyify@5.0.1

## 5. Install PO files (curl is faster)
WORKDIR /opt/online/loleaflet/po
RUN sed -i 's,wget.*https,curl -sSL4 -o $i.zip https,' /opt/online/scripts/downloadpootle.sh \
	&& /opt/online/scripts/downloadpootle.sh

## 6. configure
WORKDIR /opt/online
ENV INSTDIR="/opt/online/instdir" \
		CONFIG_OPTIONS="--enable-silent-rules --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-lokit-path=/opt/online/bundled/include"

RUN set -e \
	&& ./autogen.sh \
	&& ./configure $CONFIG_OPTIONS

## 7. Patch to build in Fedora 29
RUN sed -i 's/Werror/Wno-error/g' config.status \
	&& sed -i 's,/usr/bin/python,/usr/bin/python3.7,' /opt/online/loleaflet/util/po2json.py \
	&& sed -i 's,npm install,npm install --ignore-scripts,' Makefile.am

## 8. Apply patches to source code
ADD patch.sh /opt/online/
ADD patches/ /opt/online/patches/
RUN  set -e \
	&& ./patch.sh

## 9. build and install
RUN  set -e \
	&& make  \
	&& DESTDIR="$INSTDIR" make install

#####################
## STAGE-2 RUN    ##
###################
FROM base

LABEL maintainer="https://jeci.fr/"
LABEL RUN='docker run -d -p 9980:9980 $IMAGE'

#RUN yum install -y yum-plugin-fastestmirror

## 1. run dependencies
RUN set -xe \
	&& yum install -y \
		cairo \
		cpio \
		cups-libs \
		dbus-glib \
		findutils \
		libSM \
		libXinerama \
		poco-net \
		poco-netssl \
		which \
	&& yum clean all

ENV LO_TAR_FILENAME=${LO_BASENAME}_${LO_MAJOR}.${LO_MINOR}.${LO_BUILD}_Linux_x86-64_rpm.tar.gz
## 2. Install LibreOffice from public mirror (to match with Lool version)
RUN set -xe \
	&& curl -sSL \
					${LO_MIRROR}/libreoffice/${LO_RELEASE}/${LO_MAJOR}.${LO_MINOR}/rpm/x86_64/${LO_TAR_FILENAME} \
					-o /opt/${LO_TAR_FILENAME} \
	&& tar xzf /opt/${LO_TAR_FILENAME} -C /opt \
	&& yum install -y \
		/opt/${LO_BASENAME}_${LO_MAJOR}.${LO_MINOR}.${LO_BUILD}_Linux_x86-64_rpm/RPMS/*rpm \
	&& rm -rf /opt/${LO_BASENAME}_* \
	&& yum clean all

## 3. copy freshly built LibreOffice Online
COPY --from=builder /opt/online/instdir/ /
COPY --from=builder /opt/online/instdir/ /opt/lool/systemplate/

## 4. postinstall procedure
RUN set -ex \
	&& setcap cap_fowner,cap_mknod,cap_sys_chroot+iep /usr/bin/loolforkit \
	&& adduser -m --system lool \
	&& install -o lool -d \
				/var/cache/libreoffice-online \
				/opt/lool \
				/opt/lool/child-roots \
				/opt/lool/systemplate \
	&& chown -R lool: /opt/lool

## 5. copy the shell script which can start LibreOffice Online (loolwsd)
ADD run-lool.sh /
RUN sed -i "s,lo_template_path=.*,lo_template_path=/opt/${LO_BASENAME,,}${LO_MAJOR} \"," /run-lool.sh

## 6. setup as user "lool"
USER lool
RUN set -ex \
	&& loolwsd-systemplate-setup /opt/lool/systemplate /opt/${LO_BASENAME,,}${LO_MAJOR}

EXPOSE 9980

CMD ["bash", "/run-lool.sh"]
