# docker-builder-libreofficeonline
Make a Docker image to easely build Libreoffice Online

This will proceduce a debian package only.

## Procedure

1. first git clone libreoffice pocoproject

``` bash
git clone https://anongit.freedesktop.org/git/libreoffice/online.git
```

2. checkout a tag version

``` bash
cd online
git checkout 3.2.0-4
```

3. lunch the builder with docker

``` bash
docker run --rm -it -v "$PWD:/opt/online" jeci/loolbuilder
```

This will build lool in your directory and procude 2 debian packages :
- loolwsd_3.2.0-4_amd64.deb
- loolwsd-dbgsym_3.2.0-4_amd64.deb

## Build the builder

``` bash
docker build -t jeci/loolbuilder .
docker login
docker push jeci/loolbuilder
```
