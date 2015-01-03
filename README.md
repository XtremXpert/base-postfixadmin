# Introducción

Este repositorio alberga un *contenedor Docker* para montar PostfixAdmin, está automatizado en el Registry Hub de Docker [luispa/base-postfixadmin](https://registry.hub.docker.com/u/luispa/base-postfixadmin/) conectado con el proyecto en [GitHub base-postfixadmin](https://github.com/LuisPalacios/base-postfixadmin)


## Ficheros

* **Dockerfile**: Para crear la base de servicio.
* **do.sh**: Para arrancar el contenedor creado con esta imagen.

## Instalación de la imagen

Para usar la imagen desde el registry de docker hub

    totobo ~ $ docker pull luispa/base-postfixadmin


## Clonar el repositorio

Si quieres clonar el repositorio lo encontrarás en Github, este es el comando poder trabajar con él directamente

    ~ $ clone https://github.com/LuisPalacios/docker-postfixadmin.git

Luego puedes crear la imagen localmente con el siguiente comando

    $ docker build -t luispa/base-postfixadmin ./
