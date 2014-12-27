#!/bin/bash
#
# ENTRYPOINT script for "POSTFIXADMIN" Service
#
#set -eux

## Link con SQL
#
#
#if [ -z "${MYSQL_PORT_3306_TCP}" ]; then
#	echo >&2 "error: falta la variable MYSQL_PORT_3306_TCP"
#	echo >&2 "  Olvidaste --link un_contenedor_mysql:mysql ?"
#	exit 1
#fi
#  La dirección IP del HOST donde reside MySQL se calcula automáticamente
#mysqlLink="${MYSQL_PORT_3306_TCP#tcp://}"
#mysqlHost=${mysqlLink%%:*}
#mysqlPort=${mysqlLink##*:}

## Usuario y password de root en el MYSQL Server
#
#  #Tiene que estar hecho el Link con el contenedor MySQL y desde él
#  #averiguo la contraseña de root (MYSQL_ENV_MYSQL_ROOT_PASSWORD)
#	#if [ "${SQL_ROOT}" = "root" ]; then	
#	#	: ${SQL_ROOT_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
#	#fi
#
if [ -z "${mysqlLink}" ]; then
	echo >&2 "error: falta la variable mysqlLink"
	exit 1
fi
if [ -z "${mysqlHost}" ]; then
	echo >&2 "error: falta la variable mysqlHost"
	exit 1
fi
if [ -z "${mysqlPort}" ]; then
	echo >&2 "error: falta la variable mysqlPort"
	exit 1
fi
: ${SQL_ROOT:="root"}
if [ -z "${SQL_ROOT_PASSWORD}" ]; then
	echo >&2 "error: falta la variable MYSQL_ROOT_PASSWORD"
	exit 1
fi

## Variables para crear la BD del servicio
#
if [ -z "${SERVICE_DB_USER}" ]; then
	echo >&2 "error: falta la variable SERVICE_DB_USER"
	exit 1
fi
if [ -z "${SERVICE_DB_PASS}" ]; then
	echo >&2 "error: falta la variable SERVICE_DB_PASS"
	exit 1
fi
if [ -z "${SERVICE_DB_NAME}" ]; then
	echo >&2 "error: falta la variable SERVICE_DB_NAME"
	exit 1
fi


## Variables para crear el administrador de postfixadmin
#
if [ -z "${POSTFIXADMIN_ADMIN_USER}" ]; then
	echo >&2 "error: falta la variable POSTFIXADMIN_ADMIN_USER"
	exit 1
fi
if [ -z "${POSTFIXADMIN_ADMIN_PASS}" ]; then
	echo >&2 "error: falta la variable POSTFIXADMIN_ADMIN_PASS"
	exit 1
fi

## Servidor imap
#
#if [ -z "${ROUNDCUBE_IMAP_HOST}" ]; then
#	echo >&2 "error: falta la variable ROUNDCUBE_IMAP_HOST"
#	exit 1
#fi
## Servidor smtp
#
#if [ -z "${ROUNDCUBE_SMTP_HOST}" ]; then
#	echo >&2 "error: falta la variable ROUNDCUBE_SMTP_HOST"
#	exit 1
#fi

# Muestro las variables
#
echo >&2 "Tengo todas las variables"
echo >&2 "SERVICE_DB_USER: ${SERVICE_DB_USER}"
echo >&2 "SERVICE_DB_PASS: ${SERVICE_DB_PASS}"
echo >&2 "SERVICE_DB_NAME: ${SERVICE_DB_NAME}"
echo >&2 "SQL_ROOT: ${SQL_ROOT}"
echo >&2 "SQL_ROOT_PASSWORD: ${SQL_ROOT_PASSWORD}"
echo >&2 "mysqlHost: ${mysqlHost}"
echo >&2 "mysqlPort: ${mysqlPort}"
echo >&2 "POSTFIXADMIN_ADMIN_USER: ${POSTFIXADMIN_ADMIN_USER}"
echo >&2 "POSTFIXADMIN_ADMIN_PASS: ${POSTFIXADMIN_ADMIN_PASS}"

# Creo un fichero de configuración "local".
#
# Nota: El fichero de configuración config.inc.php es el principal, pero
# el config.local.php es el que tiene las modificaciones para esta instalación.
#
SERVICE_CONFIG_FILE="/root/postfixadmin/config.local.php"
if [ ! -f ${SERVICE_CONFIG_FILE} ]; then 
cat << EOLOCALCONFIG > ${SERVICE_CONFIG_FILE}
<?php

\$CONF['configured'] = true;

\$CONF['database_type'] = 'mysqli';
\$CONF['database_user'] = '${SERVICE_DB_USER}';
\$CONF['database_password'] = '${SERVICE_DB_PASS}';
\$CONF['database_name'] = '${SERVICE_DB_NAME}';
\$CONF['database_host'] = '${mysqlLink}';

\$CONF['default_language'] = 'es';

\$CONF['setup_password'] = '2319d0b7b9615dd0f6cc3f948b0f3a3e:9e9eb3cdce5b025c4ebcad323ae9d4e093293ecf';

?>
EOLOCALCONFIG
echo >&2 "He creado el fichero ${SERVICE_CONFIG_FILE}"
fi

## ---------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------
#
#  BASE DE DATOS: 
#
#  Si no existe, creo la base de datos en el servidor MySQL, notar
#  que debemos tener las variables con el nombre de la base de datos, 
#  el nombre del usuario y su contraseña
#

TERM=dumb php -- "${mysqlLink}" "${SQL_ROOT}" "${SQL_ROOT_PASSWORD}" "${SERVICE_DB_NAME}" "${SERVICE_DB_USER}" "${SERVICE_DB_PASS}" <<'EOPHP'
<?php
////
//
// Gestor de creación de la base de datos, usuario y contraseña.
// Si ya existe la base de datos entonces no se hace nada.
//
// Argumentos que se esperan: 
//
// argv[1] : Servidor MySQL en formato X.X.X.X:PPPP
// argv[2] : SQL_ROOT 			--> "root"  Usuario root
// argv[3] : SQL_ROOTPASSWORD	--> "<contraseña_de_root>
// argv[4] : SERVICE_DB_NAME	--> Nombre de la base de datos
// argv[5] : SERVICE_DB_USER	--> Usuario a crear
// argv[6] : SERVICE_DB_PASS	--> Contraseña de dicho usuario
//
// Ejemplo: 
//   php -f sql_test.php 192.168.1.245:3306 root rootpass mi_db mi_user mi_user_pass
//
// Autor: Luis Palacios (Nov 2014)
//

// Consigo la direccio IP y el puerto del servidor MySQL
//
list($host, $port) = explode(':', $argv[1], 2);

// Conecto con el servidor MySQL como root
//
$mysql = new mysqli($host, $argv[2], $argv[3], '', (int)$port);
if ($mysql->connect_error) {
   file_put_contents('php://stderr', '*** MySQL *** | MySQL - Error de conexión: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
   exit(1);
} else {
	printf("*** MySQL *** | MySQL Server: %s - La conexión ha sido un éxito\n", $mysql->real_escape_string($host) ); 
}

// Informo sobre la posible existencia de la base de datos
//
if ( $resultado = $mysql->query('SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME ="' . $mysql->real_escape_string($argv[4]) . '"') ) {
 if( mysqli_num_rows($resultado)>=1) {
	printf("*** MySQL *** | La BD '%s' ya existe, no necesito crearla de nuevo\n", $mysql->real_escape_string($argv[4]) ); 
	exit(0);
 } else {
	printf("*** MySQL *** | La base de datos '%s' NO existe, voy a crearla\n", $mysql->real_escape_string($argv[4]) ); 
 }
}

// Si no existía ya entonces creo la base de datos
//
if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '`')) {
	file_put_contents('php://stderr', '*** MySQL *** | MySQL - Error de creación de la base de datos: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

// Una vez más, vuelvo a comprobar que existe la Base de Datos... 
//
if ( $resultado = $mysql->query('SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME ="' . $mysql->real_escape_string($argv[4]) . '"') ) {
 if( !mysqli_num_rows($resultado)>=1) {
	file_put_contents('php://stderr', '*** MySQL *** | La base de datos no existe, no puedo seguir, error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
 }
}

// Selecciono la base de datos
//
$mysql->select_db( 'mysql' ) or die('*** MySQL *** | No se pudo seleccionar la base de datos mysql');

// Averiguo si el usuario ya existe
//
if ( $resultado = $mysql->query('SELECT User FROM user WHERE User="' . $mysql->real_escape_string($argv[5]) . '"') ) {
 if( !mysqli_num_rows($resultado)>=1) {

 	// No existe, lo creo
 	//
	printf("*** MySQL *** | El usuario '%s' no existe, voy a crearlo\n", $mysql->real_escape_string($argv[5]) ); 
	if (!$mysql->query('CREATE USER "' . $mysql->real_escape_string($argv[5]) . '"@"%" IDENTIFIED BY "' . $mysql->real_escape_string($argv[6]) . '"')) {
		file_put_contents('php://stderr', '*** MySQL *** | MySQL - Error al intentar crear el usuario: ' . $mysql->error . "\n");
		$mysql->close();
		exit(1);
	} else {
		printf("*** MySQL *** | La creación del usuario '%s' fue un éxito\n", $mysql->real_escape_string($argv[5]) ); 
	}
  }  else {
	printf("*** MySQL *** | El usuario '%s' ya existe\n", $mysql->real_escape_string($argv[5]) ); 
  }
	
  // Asigno a este usuario todos los privilegios sobre la nueva BD
  //
  if (!$mysql->query('GRANT ALL ON ' . $mysql->real_escape_string($argv[4]) . '.* TO "' . $mysql->real_escape_string($argv[5]) . '"@"%"')) {
	file_put_contents('php://stderr', '*** MySQL *** | MySQL - Error al intentar darle todos los permisos al usuario: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
  } else {
	printf("*** MySQL *** | Asignados con éxito los permisos para el usuario '%s' en la base de datos '%s'\n", $mysql->real_escape_string($argv[5]) , $mysql->real_escape_string($argv[4]) ); 
  }
	
} else {
	file_put_contents('php://stderr', '*** MySQL *** | La búsqueda del usuario devolvió error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
} 

$mysql->close();
exit(0);

?>
EOPHP


## ---------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------
#
#  ESTRUCTURA DE TABLAS
#
#  Creo las tablas, si no están ya creadas, en la base de datos
#

## Creo (si hace falta) la estructura de tablas 
if [ $(mysql -h ${mysqlHost} -P ${mysqlPort}  -N -s -u ${SQL_ROOT} --password=${SQL_ROOT_PASSWORD} -e "select count(*) from information_schema.tables where table_schema='${SERVICE_DB_NAME}' and table_name='mailbox';") -eq 0 ]; then
  	/usr/local/bin/php -c /usr/local/lib/php.ini /root/postfixadmin/setup.php > /dev/null
	echo >&2 "He creado las tablas de la base de datos"	
else
	echo >&2 "La base de datos ya tiene las tablas creadas"
fi

## ---------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------
## ---------------------------------------------------------------------------------
#
#  USUARIO ADMINISTRADOR
#
#  Creo (si hace falta) el usuario administrador
#
if [ $(mysql -h ${mysqlHost} -P ${mysqlPort}  -N -s -u ${SQL_ROOT} --password=${SQL_ROOT_PASSWORD} -D ${SERVICE_DB_NAME} -e "select count(*) from admin where username='${POSTFIXADMIN_ADMIN_USER}';") -eq 0 ]; then

	## Genero el usuario admin
	cd /root/postfixadmin
	export POSTFIXADMIN_ADMIN_PASS_CRYPTED=`php -r 'require_once("common.php"); $password = pacrypt ("$argv[1]"); print $password;' $POSTFIXADMIN_ADMIN_PASS`
	
	now=`date "+%Y-%m-%d %H:%M:%S"`
	mysql -h ${mysqlHost} -P ${mysqlPort} -u ${SERVICE_DB_USER} --password=${SERVICE_DB_PASS} -D ${SERVICE_DB_NAME} -e <<EOSQLA "INSERT INTO admin VALUES ('$POSTFIXADMIN_ADMIN_USER','$POSTFIXADMIN_ADMIN_PASS_CRYPTED',1,'${now}','${now}',1);
INSERT INTO domain VALUES ('ALL','',0,0,0,0,'',0,'${now}','${now}',1); 
INSERT INTO domain_admins VALUES ('$POSTFIXADMIN_ADMIN_USER','ALL','${now}',1);"
EOSQLA

	echo >&2 "He creado el usuario administrador"	
else
	echo >&2 "La tabla admin ya tenía el usuario administrador creado"
fi

echo >&2 "--------------------- Terminó la verificación de la base de datos -----------------------" 

## Creo (si hace falta) la estructura de tablas 

## Ejecuto el comando que me pasan
#
#
exec "$@"

