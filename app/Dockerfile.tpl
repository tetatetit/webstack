#!/bin/bash

cat <<END
$NOEDIT_MSG

FROM $IMAGE_IN:$TAG

RUN apt-get update \\
 # Locales \\
    && apt-get install -y locales locales-all \\
    && locale-gen \\
    && sed -ri '/en_US|es_ES|ru_RU|uk_UA/s/^#//g' /etc/locale.gen \\
    && locale-gen \\
    && update-locale LANG=en_US.UTF-8 \\
# sendmail \\
    && apt-get install -y msmtp-mta \\
    && rm -f /etc/msmtprc \\
    && ln -s /var/www/msmtprc /etc/msmtprc \\
# Misc admin/config/test/develop stuff \\
    && apt-get install -y man wget vim nano mc screen git rsync mariadb-client cron aptitude info bzip2 augeas-tools \\
                          command-not-found xz-utils ctags dialog net-tools htop atop byobu screenie gawk \\
                          libpng12-dev libjpeg-dev libpq-dev libmcrypt-dev \\
# Hint on command not found and cleanup \\
                          command-not-found \\
# SSH server \\
                          openssh-server \\
    && augtool set /files//etc/ssh/sshd_config/PermitRootLogin "yes" \\
# Vim tweaks \\
    && sed -i 's/"syntax on/syntax on/g' /etc/vim/vimrc \\
# Cleanup and update \\
    && rm -rf /var/lib/apt/lists/* \\
    && update-command-not-found \\
# Entrypoint/startup scripts \\
    && echo \\
"#!/bin/bash\n\\
set -e\n\\
\n\\
docker-entrypoint-hook.sh\n\\
\n\\
[ -f /var/www/msmtprc ] || ( cat <<EOF\n\\
host smtp\n\\
from www@www\n\\
domain org\n\\
EOF\n\\
) > /etc/msmtprc\n\\
\n\\
[ ! -f /var/www/php.ini ] && touch /var/www/php.ini\n\\
[ -f /usr/sbin/a2enmod ] && [ ! -f /var/www/apache2.conf ] && touch /var/www/apache2.conf\n\\
[ -f /usr/local/bin/php-fpm ] && [ ! -f /var/www/php-fpm.conf ] && touch /var/www/php-fpm.conf\n\\
\n\\
service cron start\n\\
service ssh start\n\\
\n\\
exec \"\\\$@\"\n\\
" > /usr/local/bin/docker-entrypoint.sh \\
    && chmod +x /usr/local/bin/docker-entrypoint.sh \\
    && echo \\
"#!/bin/bash\n\\
\n\\
set -e\n\\
\n\\
" > /usr/local/bin/docker-entrypoint-hook.sh \\
    && chmod +x /usr/local/bin/docker-entrypoint-hook.sh
END

[[ $TAG != *hhvm* ]] && cat <<END

RUN \\
# php.ini conf to in volume \\
    ln -s /var/www/php.ini /usr/local/etc/php/conf.d/mounted-php.ini \\
# Drupal/Wordpress/Joomla/Wikimedia stuff \\
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \\
    && docker-php-ext-install gd mysqli opcache mcrypt mbstring pdo pdo_mysql pdo_pgsql zip \\
  # Set recommended PHP.ini settings \\
  # see https://secure.php.net/manual/en/opcache.installation.php \\
    && { \\
                echo 'opcache.memory_consumption=128'; \\
                echo 'opcache.interned_strings_buffer=8'; \\
                echo 'opcache.max_accelerated_files=4000'; \\
                echo 'opcache.revalidate_freq=2'; \\
                echo 'opcache.fast_shutdown=1'; \\
                echo 'opcache.enable_cli=1'; \\
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini \\
  # Drush \\
    && curl -sS https://getcomposer.org/installer | php \\
    && mv composer.phar /usr/local/bin/composer \\
    && ln -s /usr/local/bin/composer /usr/bin/composer \\
    && echo "deb http://httpredir.debian.org/debian jessie main contrib" >> /etc/apt/sources.list \\
    && git clone --depth 1 https://github.com/drush-ops/drush.git /usr/local/src/drush \\
    && ln -s /usr/local/src/drush/drush /usr/bin/drush \\
    && cd /usr/local/src/drush && composer install \\
# XDebug \\
    && yes | pecl install xdebug \\
    && echo "zend_extension=\$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \\
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \\
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini
END

[[ $TAG == *apache* ]] && cat <<END

RUN ln -s /var/www/apache2.conf /etc/apache2/conf-enabled/mounted-apache2.conf \\
 && a2enmod rewrite expires

EXPOSE 22 443

CMD ["apache2-foreground"]
END

[[ $TAG == *fpm* ]] && cat <<END

RUN    ln -s /var/www/php-fpm.conf /usr/local/etc/php-fpm.d/mounted-php-fpm.conf \\
    && sed -i "s/\(listen *= *\).*/\1\/var\/www\/fastcgi.sock/" /usr/local/etc/php-fpm.d/zz-docker.conf \\
    && echo "listen.owner = www-data\nlisten.group = www-data" >> /usr/local/etc/php-fpm.d/zz-docker.conf

EXPOSE 443

CMD ["php-fpm"]     
END

cat <<END

ENTRYPOINT ["docker-php-entrypoint.sh"]

#TODO:
# * fix term not set
# * add developer tools to vim to php debugging, autocompletion, symbols sidebar, make sure xdebug enable for local debug
# * install drush on hhvm
# * shorcuts on php-fpm and hhvm sockets
# * may be something of these: httpry pktstat apachetop wtop
# whois slurm iftop bmon tcptrack iptraf tcpdump speedometer ifstat vnstat nload wavemon netcap nethogs bwm-ng cbm
END