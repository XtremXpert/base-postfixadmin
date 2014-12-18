#
# Postfixadmin container by Luispa, Nov 2014
#
# -----------------------------------------------------
#

# Desde donde parto...
#
FROM php:5.6

# Autor
#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Update and install required packages
RUN apt-get update && \
	apt-get install -y 	curl             \  
	                    mysql-client     \ 
	                    locales          \
	                    libssl-dev    \
	                    libc-client2007e-dev \
	                    libkrb5-dev \
	                    openssl && \
	rm -rf /var/lib/apt/lists/*

# Preparo locales
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# Preparo el timezone para Madrid
#
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# Añado las extensiones PHP que necesita PostfixAdmin
RUN /usr/local/bin/docker-php-ext-configure imap --with-imap-ssl --with-kerberos
RUN /usr/local/bin/docker-php-ext-install mysqli imap mbstring

# Pongo mi propio php.ini
COPY php.ini /usr/local/lib/

# Descarga, el software quedará en /root/postfixadmin
WORKDIR /root
RUN curl http://downloads.sourceforge.net/project/postfixadmin/postfixadmin/postfixadmin-2.92/postfixadmin-2.92.tar.gz -L -O
RUN tar zxvf postfixadmin-2.92.tar.gz
RUN mv postfixadmin-2.92 postfixadmin
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

