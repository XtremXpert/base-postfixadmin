#!/bin/bash

cmd_php="php -S 0.0.0.0:80 -c php.ini -t /var/www"

wait_for_mysql() {
  until mysql --host=$DBHOST --user=$DBUSER --password=$DBPASS --execute="USE $DBNAME;" &>/dev/null; do
    echo "waiting for mysql to start..."
    sleep 2
  done
}

wait_for_php() {
  until curl --output /dev/null --silent --get --fail "http://localhost"; do
    echo "waiting for php to start..."
    sleep 2
  done
}

# Replace {{ ENV }} vars
_envtpl() {
  mv "$1" "$1.tpl" # envtpl requires files to have .tpl extension
  envtpl "$1.tpl"
}

init_config() {
  _envtpl /var/www/config.local.php
}

init_db() {
  $cmd_php &
  wait_for_php
  pid_php=$!
  setup_password="s3cr3t";
  salt=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
  password_hash=$(echo -n "$salt:$setup_password" | sha1sum | cut -d ' ' -f 1)
  setup_password_hash="$salt:$password_hash"
  echo "<?php \$CONF['setup_password'] = '$setup_password_hash';">/config/___setup_password.php
  curl --silent  --output /dev/null --data "form=createadmin&setup_password=$setup_password&username=$ADMIN_USERNAME&password=$ADMIN_PASSWORD&password2=$ADMIN_PASSWORD" http://localhost/setup.php
  kill $pid_php
  wait $pid_php 2>/dev/null
}

wait_for_mysql
init_config

if [ ! -f .initialized ]; then
  init_db
  touch .initialized
fi

$cmd_php
