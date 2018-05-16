FROM debian as poco
### STAGE 1 - Build POCO ###

RUN mkdir /opt/libpoco
WORKDIR /opt/libpoco

ENV POCO_VERSION=1.7.6

RUN apt-get update -y \
		&& apt-get install -y \
			m4 automake fakeroot debhelper dh-systemd build-essential unixodbc-dev \
			libexpat1-dev default-libmysqlclient-dev libpcre3-dev libsqlite3-dev \
			libssl-dev unzip curl xz-utils

RUN curl  -sSL --fail -o poco-poco-${POCO_VERSION}-release.zip \
			https://github.com/pocoproject/poco/archive/poco-${POCO_VERSION}-release.zip \
		&& unzip poco-poco-${POCO_VERSION}-release.zip \
		&& mv poco-poco-${POCO_VERSION}-release poco \
		&& rm poco-poco-${POCO_VERSION}-release.zip

# wget http://http.debian.net/debian/pool/main/p/poco/poco_1.7.6+dfsg1-5+deb9u1.debian.tar.xz
# tar xf poco_1.7.6+dfsg1-5+deb9u1.debian.tar.xz -C docker/libpoco-dev
ADD libpoco-dev /opt/libpoco/poco

RUN tar cJf poco_${POCO_VERSION}-lool.orig.tar.xz poco
WORKDIR /opt/libpoco/poco
RUN dpkg-buildpackage -us -uc -j4
RUN rm ../*-dbgsym_*.deb && dpkg -i ../*.deb


FROM debian
### STAGE 2 - Configure debian to build lool ###
# Reference : https://www.boniface.me/post/building-libreoffice-online-for-debian/

RUN apt-get update -y \
		&& apt-get install -y libpng-dev libcap-dev libtool m4 automake fakeroot \
			debhelper dh-systemd build-essential unixodbc-dev libreoffice \
			python-polib nodejs-legacy node-jake libghc-zlib-bindings-dev \
			libghc-zlib-dev git pkg-config libcppunit-dev libpam0g-dev python-lxml \
			libexpat1-dev default-libmysqlclient-dev libpcre3-dev libsqlite3-dev \
			libssl-dev devscripts

COPY --from=poco /opt/libpoco/*.deb /opt/libpoco/
RUN dpkg -i /opt/libpoco/*.deb \
		&& rm /opt/libpoco/*.deb

WORKDIR /opt/npm
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
		&& apt-get install -y nodejs \
		&& npm install uglify-js exorcist d3 evol-colorpicker bootstrap eslint \
			browserify-css d3 popper.js \
		&& npm install -g jake

WORKDIR /opt
ADD build.sh /opt

CMD /opt/build.sh
