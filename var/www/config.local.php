<?php
$CONF['configured'] = true;
$CONF['database_type'] = 'mysqli';
$CONF['database_host'] = {{ DBHOST }};
$CONF['database_user'] = {{ DBUSER }};
$CONF['database_password'] = {{ DBPASS }};
$CONF['database_name'] = {{ DBNAME }};
$CONF['default_aliases'] = array (
    'abuse' => 'admin',
    'hostmaster' => 'admin',
    'postmaster' => 'admin',
    'webmaster' => 'admin'
);
$CONF['show_footer_text'] = 'NO';
