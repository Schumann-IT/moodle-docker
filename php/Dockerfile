FROM composer:2 AS composer

FROM php:8.1-fpm

ARG MOODLE_SERIES=stable405
ARG MOODLE_VERSION=latest-405
ARG MOODLE_RUN_COMPOSER_INSTALL=1

ARG MOODLE_THEME_ADAPTABLE_ZIP_URL=https://moodle.org/plugins/download.php/40095/theme_adaptable_moodle45_2024100518.zip
ARG MOODLE_LOCAL_PROFILECOHORT_ZIP_URL=https://moodle.org/plugins/download.php/38507/local_profilecohort_moodle45_2024100702.zip
ARG MOODLE_LOCAL_CNW_SMARTCOHORT_ZIP_URL=https://moodle.org/plugins/download.php/29804/local_cnw_smartcohort_moodle42_2023081800.zip
ARG MOODLE_BLOCK_COURSEFEEDBACK_ZIP_URL=https://moodle.org/plugins/download.php/35159/block_coursefeedback_moodle44_2025022700.zip

ENV MOODLE_WWWROOT=http://localhost:8080 \
    MOODLE_DBTYPE=mysqli \
    MOODLE_DBHOST=db \
    MOODLE_DBNAME=moodle \
    MOODLE_DBUSER=moodle \
    MOODLE_DBPASSWORD=moodle \
    MOODLE_DBPREFIX=mdl_ \
    MOODLE_DATAROOT=/var/www/moodledata \
    MOODLE_REVERSEPROXY=0 \
    MOODLE_SSLPROXY=0 \
    MOODLE_ROUTERCONFIGURED=0 \
    MOODLE_RUN_INSTALL=0 \
    MOODLE_RUN_UPGRADE=0 \
    MOODLE_SITE_FULLNAME=Moodle \
    MOODLE_SITE_SHORTNAME=Moodle \
    MOODLE_ADMIN_USER=admin \
    MOODLE_ADMIN_PASSWORD=admin123! \
    MOODLE_ADMIN_EMAIL=admin@example.local \
    PHP_DISPLAY_ERRORS=0 \
    PHP_ERROR_REPORTING=E_ALL\&~E_DEPRECATED\&~E_STRICT \
    PHP_LOG_ERRORS=1 \
    PHP_EXPOSE_PHP=0

ENV ETC_DIR=/usr/local/etc
ENV PHP_INI_DIR=$ETC_DIR/php

RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    ca-certificates \
    curl \
    unzip \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    wget \
  && rm -rf /var/lib/apt/lists/*

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions \
  && install-php-extensions \
    bcmath \
    curl \
    exif \
    gd \
    intl \
    ldap \
    mbstring \
    mysqli \
    opcache \
    pdo_mysql \
    pgsql \
    pdo_pgsql \
    soap \
    sodium \
    xmlrpc \
    xsl \
    zip

RUN pecl install -o -f redis \
  && docker-php-ext-enable redis \
  && rm -rf /tmp/pear

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

COPY ./php/php.ini "$PHP_INI_DIR/conf.d/99-moodle.ini"
COPY ./php/php-fpm.conf "$ETC_DIR/php-fpm.d/zz-moodle.conf"

RUN mkdir -p /var/www/html \
  && curl -fsSL -o /tmp/moodle.tgz "https://packaging.moodle.org/${MOODLE_SERIES}/moodle-${MOODLE_VERSION}.tgz" \
  && tar -xzf /tmp/moodle.tgz -C /var/www/html --strip-components=1 \
  && rm -f /tmp/moodle.tgz \
  && mkdir -p /tmp/moodle-plugins \
  && curl -fsSL -o /tmp/moodle-plugins/theme_adaptable.zip "${MOODLE_THEME_ADAPTABLE_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/theme_adaptable.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/theme/adaptable \
  && cp -R /tmp/moodle-plugins/adaptable /var/www/html/theme/adaptable \
  && curl -fsSL -o /tmp/moodle-plugins/local_profilecohort.zip "${MOODLE_LOCAL_PROFILECOHORT_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/local_profilecohort.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/local/profilecohort \
  && cp -R /tmp/moodle-plugins/profilecohort /var/www/html/local/profilecohort \
  && curl -fsSL -o /tmp/moodle-plugins/local_cnw_smartcohort.zip "${MOODLE_LOCAL_CNW_SMARTCOHORT_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/local_cnw_smartcohort.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/local/cnw_smartcohort \
  && cp -R /tmp/moodle-plugins/cnw_smartcohort /var/www/html/local/cnw_smartcohort \
  && curl -fsSL -o /tmp/moodle-plugins/block_coursefeedback.zip "${MOODLE_BLOCK_COURSEFEEDBACK_ZIP_URL}" \
  && unzip -q /tmp/moodle-plugins/block_coursefeedback.zip -d /tmp/moodle-plugins \
  && rm -rf /var/www/html/blocks/coursefeedback \
  && mkdir -p /var/www/html/blocks/coursefeedback \
  && COURSEFEEDBACK_DIR="$(find /tmp/moodle-plugins -maxdepth 1 -type d -name '*coursefeedback*' | head -n 1)" \
  && if [ -z "${COURSEFEEDBACK_DIR}" ]; then echo "Unable to locate extracted coursefeedback directory"; exit 1; fi \
  && cp -R "${COURSEFEEDBACK_DIR}"/* /var/www/html/blocks/coursefeedback/ \
  && rm -rf /tmp/moodle-plugins \
  && if [ "${MOODLE_RUN_COMPOSER_INSTALL}" = "1" ]; then \
      export COMPOSER_ALLOW_SUPERUSER=1; \
      composer --no-interaction --working-dir=/var/www/html install --no-dev --classmap-authoritative; \
    fi

COPY ./php/entrypoint.sh /usr/local/bin/moodle-entrypoint
RUN chmod +x /usr/local/bin/moodle-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/moodle-entrypoint"]
