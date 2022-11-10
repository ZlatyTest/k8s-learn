# cat Dockerfile
FROM php:7.4-fpm
#from https://github.com/wikimedia/mediawiki-docker/blob/daebab6abd474474deb62c5544127f86dd507172/1.37/fpm/DockerfileZZ

# System dependencies
#RUN set -eux; \
#       \
#       apt-get update; \
#       apt-get install -y --no-install-recommends \
#               git \
#               librsvg2-bin \
#               imagemagick \
#               # Required for SyntaxHighlighting
#               python3 \
#       ; \
#       rm -rf /var/lib/apt/lists/*
#
# Install the PHP extensions we need
RUN set -eux; \
        \
        savedAptMark="$(apt-mark showmanual)"; \
        \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                libicu-dev \
                libonig-dev \
        ; \
        \
        docker-php-ext-install -j "$(nproc)" \
                intl \
                mbstring \
                mysqli \
                opcache \
        ; \
        \
    pecl channel-update pecl.php.net; \
        pecl install APCu-5.1.21; \
        docker-php-ext-enable \
                apcu \
        ; \
    pecl install redis; \
        docker-php-ext-enable \
                redis \
        ; \
        rm -r /tmp/pear; \
        \
        # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
        apt-mark auto '.*' > /dev/null; \
        apt-mark manual $savedAptMark; \
        ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
                | awk '/=>/ { print $3 }' \
                | sort -u \
                | xargs -r dpkg-query -S \
                | cut -d: -f1 \
                | sort -u \
                | xargs -rt apt-mark manual; \
        \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        rm -rf /var/lib/apt/lists/*


# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini


CMD ["php-fpm"]
