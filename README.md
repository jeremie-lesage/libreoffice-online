# Docker image of libreoffice-online

Build script to make a LibreOffice Online docker image from public upstream.


## Build

``` bash
TAG=$(git rev-parse --abbrev-ref HEAD)
docker build -t jeci/libreoffice-online:$TAG .
docker login
docker push jeci/libreoffice-online:$TAG
```


## Run

If no certificat are present in `/etc/libreoffice-online` a self-signed certificat
was made by at first start. It is better to create a volume for this directory.

``` bash
docker run --rm -d \
	-p 9980:9980 \
	-v "$PWD/etc/:/etc/libreoffice-online" \
	jeci/libreoffice-online:$TAG

```
