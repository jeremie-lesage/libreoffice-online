# Docker image of libreoffice-online

Build script to make a LibreOffice Online docker image from public upstream.


## Build

``` bash
TAG=$(git rev-parse --abbrev-ref HEAD)
docker build -t jeci/libreoffice-online:$TAG .
docker login
docker push jeci/libreoffice-online:$TAG
```
