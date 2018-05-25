FROM ubuntu

# get the latest fixes
RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
			libpng-dev libcap-dev libtool m4 automake fakeroot \
			debhelper dh-systemd build-essential unixodbc-dev \
			python-polib nodejs node-jake libghc-zlib-bindings-dev \
			libghc-zlib-dev git pkg-config libcppunit-dev libpam0g-dev python-lxml \
			libexpat1-dev default-libmysqlclient-dev libpcre3-dev libsqlite3-dev \
			libssl-dev devscripts libssl1.1 libcap2-bin fontconfig

# set up 3rd party repo of Poco, dependency of loolwsd
RUN echo "deb https://collaboraoffice.com/repos/Poco/ /" >> /etc/apt/sources.list.d/poco.list \
	&& apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 0C54D189F4BA284D \
	&& apt-get update \
	&& apt-get -y install libpoco-dev

WORKDIR /opt/npm
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
		&& apt-get install -y nodejs \
		&& npm install uglify-js exorcist evol-colorpicker bootstrap eslint \
			browserify-css d3 popper.js \
		&& npm install -g jake

WORKDIR /opt
ADD build.sh /opt

CMD /opt/build.sh

RUN useradd -ms /bin/bash lool \
	&& chown lool:lool -R /opt
