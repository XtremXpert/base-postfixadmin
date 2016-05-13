FROM php:5.6

MAINTAINER Benoît "XtremXpert" Vézina <xtremxpert@xtremxpert.com>

ARG VERSION=2.93
ARG GPG_Goodwin="2D83 3163 D69B B8F6 BFEF  179D 4ECC 3566 EB7E B945"

ENV GID=991 \
    UID=991 \
    DBHOST=mariadb \
    DBUSER=postfix \
    DBNAME=postfix \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y \
        curl \  
        mysql-client \ 
        locales \
        libssl-dev \
        libc-client2007e-dev \
        libkrb5-dev \
        openssl \
    && rm -rf /var/lib/apt/lists/* \
    && PFA_TARBALL="postfixadmin-${VERSION}.tar.gz" \
    && locale-gen fr_CA.UTF-8 \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales

#RUN echo "America/Toronto" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata
#RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/

#     if [ -d '/config/tz' ]; then
#         dpkg-reconfigure -f noninteractive tzdata
#         echo "Hora actual: `date`"
#     fi
#     /Apps/data/tz:/config/tz
#     echo "Europe/Madrid" > /Apps/data/tz/timezone
 
RUN /usr/local/bin/docker-php-ext-configure imap --with-imap-ssl --with-kerberos
RUN /usr/local/bin/docker-php-ext-install mysqli imap mbstring

COPY php.ini /usr/local/lib/

WORKDIR /root
ADD https://downloads.sourceforge.net/project/postfixadmin/postfixadmin/postfixadmin-${VERSION}/${PFA_TARBALL} /root

RUN tar xzf ${PFA_TARBALL} -C /tmp && mv /tmp/postfixadmin-$VERSION/* /root/postfixadmin \

WORKDIR /root/postfixadmin

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará php -S (web server embebido)
CMD ["/usr/local/bin/php", "-c /usr/local/lib/php.ini -S 0.0.0.0:80"]

