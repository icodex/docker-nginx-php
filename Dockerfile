FROM ubuntu:18.04
LABEL maintainer="Docker-LNMP Maintainers By Shing.L <icodex@msn.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_HOST db:3306
ENV MYSQL_DATABASE database
ENV MYSQL_USER user
ENV MYSQL_PASSWORD password
ENV MEMCACHED_HOST memcached:11211
ENV REDIS_HOST redis:6379

## Base
RUN apt-get -y update \
    && apt-get -y install software-properties-common \
    && LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -s -y ppa:nginx/stable \
    && apt-get -y update \
    && apt-get -y install apt-utils curl tzdata ca-certificates wget cron bzip2 gawk unzip tar supervisor \
    && echo "Asia/Shanghai" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && echo 'ulimit -HSn 4096' >> /etc/profile \
    && mkdir -p /var/log/supervisor \
    && chmod -R 777 /var/log/supervisor \
    && echo "Success"

# php7.2-fpm
RUN apt-get -y install php7.2-fpm php7.2-pgsql php7.2-dev php7.2-mysql \
    php7.2-common php7.2-curl php7.2-xml php7.2-gd php7.2-gmp php7.2-ldap \
    php7.2-odbc php7.2-pspell php7.2-recode php7.2-sqlite3 php7.2-tidy \
    php7.2-xmlrpc php7.2-bcmath php7.2-bz2 php7.2-enchant php7.2-imap \
    php7.2-interbase php7.2-intl php7.2-mbstring php7.2-phpdbg php7.2-soap \
    php7.2-sybase php7.2-xsl php7.2-zip \
    && apt-get -y install php7.2 \
    && mkdir -p /run/php-fpm \
    && chown -R nobody:nogroup /run/php-fpm \
    && chmod -R 777 /run/php-fpm \
    && echo "Success"

RUN sed -i '1767 s#;opcache.enable=1#opcache.enable=1#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1770 s#;opcache.enable_cli=1#opcache.enable_cli=1#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1773 s#;opcache.memory_consumption=128#opcache.memory_consumption=128#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1776 s#;opcache.interned_strings_buffer=8#opcache.interned_strings_buffer=8#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1780 s#;opcache.max_accelerated_files=10000#opcache.max_accelerated_files=10000#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1798 s#;opcache.revalidate_freq=60#opcache.revalidate_freq=60#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1801 s#;opcache.revalidate_path=1#opcache.revalidate_path=1#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1805 s#;opcache.save_comments=1#opcache.save_comments=1#' /etc/php/7.2/fpm/php.ini \
    && sed -i '1808 s#;opcache.enable_file_override=0#opcache.enable_file_override=1#' /etc/php/7.2/fpm/php.ini \
    && sed -i 's#; extension_dir = "./"#extension_dir = "/usr/lib/php/20170718/"#' /etc/php/7.2/fpm/php.ini \
    && sed -i 's#;include_path = ".:/usr/share/php"#include_path = ".:/usr/include/php:/usr/share/php"#g' /etc/php/7.2/fpm/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.2/fpm/php.ini \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.2/fpm/php.ini \
    && sed -i 's#;upload_tmp_dir =#upload_tmp_dir = /tmp/#g' /etc/php/7.2/fpm/php.ini \
    && sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.2/fpm/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/7.2/fpm/php.ini \
    && rm -f /etc/php/7.2/cli/php.ini \
    && ln -sf /etc/php/7.2/fpm/php.ini /etc/php/7.2/cli/php.ini \
    && echo "Success"

RUN apt-get -y install php-memcache php-memcached php-redis php-imagick \
    php-geoip php-gettext php-gnupg php-lua php-mailparse php-sodium \
    php-uuid php-yaml php-oauth php-yac php-zmq \
    && apt-get install -y php-apcu \
    && echo "Success"

COPY ./php-fpm.conf /etc/php/7.2/fpm/
COPY ./www.conf /etc/php/7.2/fpm/pool.d/
COPY ./ioncube_loader_lin_7.2.so /usr/lib/php/20170718/
COPY ./ixed.7.2.lin /usr/lib/php/20170718/

RUN echo "[ionCubeLoader]\nzend_extension = ioncube_loader_lin_7.2.so\n\n[sg_loader]\nextension = ixed.7.2.lin" >> /etc/php/7.2/fpm/php.ini

# nginx
RUN apt-get install -y nginx \
    && apt-get install -y libnginx-mod-http-cache-purge \
    libnginx-mod-http-headers-more-filter libnginx-mod-http-uploadprogress \
    libnginx-mod-nchan libnginx-mod-http-lua \
    && echo 'ULIMIT="-n 65536"' > /etc/default/nginx \
    && echo "Success"

COPY ./ngx_pagespeed.so /usr/lib/nginx/modules/
COPY ./ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY ./ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY ./mod-pagespeed.conf /usr/share/nginx/modules-available/
COPY ./mod-brotli.conf /usr/share/nginx/modules-available/
COPY ./pagespeed_libraries_generator.sh /usr/local/sbin/
ADD ./nginx_conf.tar.gz /etc/nginx/
ADD ./app.tar.gz /

RUN mkdir -p /etc/nginx/certs \
    && openssl dhparam -out /etc/nginx/certs/dhparams.pem 2048 \
    && openssl rand 48 > /etc/nginx/certs/session_ticket.key \
    && mkdir -p /var/cache/nginx \
    && curl -sS https://getcomposer.org/installer | php7.2 -- --install-dir=/usr/local/bin --filename=composer \
    && /usr/local/sbin/pagespeed_libraries_generator.sh > /etc/nginx/conf.d/pagespeed_libraries.conf \
    && ln -sf /usr/share/nginx/modules-available/mod-pagespeed.conf /etc/nginx/modules-enabled/50-mod-pagespeed.conf \
    && ln -sf /usr/share/nginx/modules-available/mod-brotli.conf /etc/nginx/modules-enabled/50-mod-brotli.conf \
    && ln -sf /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf \
    && echo "Success"

# supervisor
RUN mkdir -p /etc/supervisor/conf.d
ADD ./init.conf /etc/supervisor/conf.d/
RUN chmod +x /app/bin/start
RUN find /var/log/ -type f -exec rm -f {} \;

# PORT
EXPOSE 80 443

# VOLUME
VOLUME /app

CMD ["/usr/bin/supervisord"]

