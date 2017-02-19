FROM php:5-apache
MAINTAINER DianQK <dianqk@icloud.com>
VOLUME /opt
WORKDIR /opt
RUN apt-get -qq update
# install common package utility and dependencies
RUN apt-get install -y \
	git unzip zip \
	libmcrypt-dev libssl-dev libcurl4-openssl-dev \
	ftp sendmail python-pygments \
	libpng-dev libjpeg-dev \
	libfreetype6-dev libjpeg62-turbo-dev libpng12-dev

# Install pdo_mysql
RUN docker-php-ext-install mysqli pdo_mysql

# Install phabricator dependencies
RUN docker-php-ext-install -j$(nproc) curl sockets mbstring mcrypt zip iconv curl pcntl ftp opcache json
RUN	docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN	docker-php-ext-install -j$(nproc) gd

# /config/issue/extension.apcu/
RUN pecl install apcu-4.0.11
RUN docker-php-ext-enable apcu

# http://127.0.0.1:8081/config/issue/config.timezone/
# Asia/Shanghai

RUN git clone https://github.com/phacility/libphutil.git
RUN git clone https://github.com/phacility/arcanist.git
RUN git clone https://github.com/phacility/phabricator.git
RUN git clone https://github.com/PHPOffice/PHPExcel.git

#
# Included PHPExcel
#
RUN cd /usr/local/etc/php/conf.d/ && \
	echo 'include_path = ".:/usr/local/lib/php:/opt/PHPExcel/Classes"' > include_path.ini;

RUN chmod -R +x .
RUN ln -s /usr/lib/git-core/git-http-backend /opt/phabricator/support/bin
RUN /opt/phabricator/bin/config set phd.user "root"
RUN echo "www-data ALL=(ALL) SETENV: NOPASSWD: /opt/phabricator/support/bin/git-http-backend" >> /etc/sudoers

ADD local.json /opt/phabricator/conf/local/local.json
# Setup apache
RUN a2enmod rewrite
ADD phabricator.conf /etc/apache2/sites-available/phabricator.conf
RUN ln -s /etc/apache2/sites-available/phabricator.conf \
    /etc/apache2/sites-enabled/phabricator.conf && \
    rm -f /etc/apache2/sites-enabled/000-default.conf
RUN service apache2 restart

# ENTRYPOINT phabricator/bin/storage upgrade

EXPOSE 20 80 443
