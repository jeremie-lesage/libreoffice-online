# Docker image of libreoffice-online

Build script to make a LibreOffice Online docker image from public upstream.


## Build

``` bash
docker build -t jeci/libreoffice-online --build-arg ONLINE_BRANCH=libreoffice-6-1 .
docker login
docker push jeci/libreoffice-online
```
