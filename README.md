Version
-------------------

Nginx(14.0, dynamic module: ngx_pagespeed, ngx_brotli)
php-fpm7.2
php-fpm7.1
php-fpm5.6

Table of Contents
-------------------

 * [Installation](#installation)
 * [Quick Start](#quick-start)
 * [Persistence](#developmentpersistence)
 * [Linked to other container](#linked-to-other-container)
 * [Adding PHP-extension](#adding-php-extension) 
 * [Logging](#logging)

Installation
-------------------

 * Install Docker 1.9+ using curl -sSL https://get.docker.com | sh
 * Pull the latest version of the image.
 
```bash
docker pull icodex/docker-nginx-php
```

or other versions (7.2, 7.1 or 5.6):

```bash
docker pull icodex/docker-nginx-php:5.6
```

Alternately you can build the image yourself.

```bash
git clone https://github.com/icodex/docker-nginx-php.git
cd docker-nginx-php
docker build -t="$USER/docker-nginx-php" .
```

Quick Start
-------------------

Run the application container:

```bash
docker run -idt --name app -p 8080:80 icodex/docker-nginx-php
```

The simplest way to login to the app container is to use the `docker exec` command to attach a new process to the running container.

```bash
docker exec -it app bash
```

Development/Persistence
-------------------

For development a volume should be mounted at `/app/`.

The updated run command looks like this.

```bash
docker run -idt --name app -p 8080:80 \
  -v /host/to/path/app:/app/ \
  icodex/docker-nginx-php
```

This will make the development.

Linked to other container
-------------------

As an example, will link with MySQL. 

```bash
docker network create icodex_net

docker run -idt --name db --net icodex_net mysql:5.7
```

Run the application container:

```bash
docker run -idt --name app -p 8080:80 \
  --net icodex_net \
  -v /host/to/path/app:/app/ \
  icodex/docker-nginx-php
```

Adding PHP-extension
-------------------

You can use one of two choices to install the required php-extensions:

1. `docker exec -it app bash -c 'apt-get update && apt-get -y install php-mongo && rm -rf /var/lib/apt/lists/*'`

2. Create your container on based the current. Сontents Dockerfile:

```
FROM icodex/docker-nginx-php

RUN apt-get update \
    && apt-get -y install php-mongo \
    && rm -rf /var/lib/apt/lists/* 

WORKDIR /app/

EXPOSE 80

CMD ["/usr/bin/supervisord"]
```

Next step,

```bash
docker build -t docker-nginx-php .
docker run -idt --name app -p 8080:80 docker-nginx-php
```

>See installed php-extension: `docker exec -it app php -m`

Logging
-------------------

All the logs are forwarded to stdout and sterr. You have use the command `docker logs`.

```bash
docker logs app
```

####Split the logs

You can then simply split the stdout & stderr of the container by piping the separate streams and send them to files:

```bash
docker logs app > stdout.log 2>stderr.log
cat stdout.log
cat stderr.log
```

or split stdout and error to host stdout:

```bash
docker logs app > -
docker logs app 2> -
```

####Rotate logs

Create the file `/etc/logrotate.d/docker-containers` with the following text inside:

```
/var/lib/docker/containers/*/*.log {
    rotate 31
    daily
    nocompress
    missingok
    notifempty
    copytruncate
}
```
> Optionally, you can replace `nocompress` to `compress` and change the number of days.

License
-------------------

Nginx + PHP-FPM docker image is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
