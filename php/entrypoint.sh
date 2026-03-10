#!/usr/bin/env sh
set -eu

PHP_INI_OVERRIDE_FILE="/usr/local/etc/php/conf.d/99-runtime-env.ini"

cat > "$PHP_INI_OVERRIDE_FILE" <<EOF
display_errors=${PHP_DISPLAY_ERRORS:-0}
log_errors=${PHP_LOG_ERRORS:-1}
expose_php=${PHP_EXPOSE_PHP:-0}
error_reporting=${PHP_ERROR_REPORTING:-E_ALL\&~E_DEPRECATED\&~E_STRICT}
EOF

if [ ! -f /var/www/html/config.php ]; then
  : "${MOODLE_WWWROOT:?MOODLE_WWWROOT is required}"
  : "${MOODLE_DBTYPE:?MOODLE_DBTYPE is required}"
  : "${MOODLE_DBHOST:?MOODLE_DBHOST is required}"
  : "${MOODLE_DBNAME:?MOODLE_DBNAME is required}"
  : "${MOODLE_DBUSER:?MOODLE_DBUSER is required}"
  : "${MOODLE_DBPASSWORD:?MOODLE_DBPASSWORD is required}"
  : "${MOODLE_DBPREFIX:?MOODLE_DBPREFIX is required}"
  : "${MOODLE_DATAROOT:?MOODLE_DATAROOT is required}"
  : "${MOODLE_REVERSEPROXY:=0}"
  : "${MOODLE_SSLPROXY:=0}"
  : "${MOODLE_ROUTERCONFIGURED:=0}"

  mkdir -p "${MOODLE_DATAROOT}" || true
  chown -R www-data:www-data "${MOODLE_DATAROOT}" || true
  chmod 0777 "${MOODLE_DATAROOT}" || true

  cat > /var/www/html/config.php <<PHP
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = '${MOODLE_DBTYPE}';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${MOODLE_DBHOST}';
\$CFG->dbname    = '${MOODLE_DBNAME}';
\$CFG->dbuser    = '${MOODLE_DBUSER}';
\$CFG->dbpass    = '${MOODLE_DBPASSWORD}';
\$CFG->prefix    = '${MOODLE_DBPREFIX}';
\$CFG->dboptions = [
  'dbpersist' => false,
  'dbport' => '',
  'dbsocket' => false,
];

\$CFG->wwwroot   = '${MOODLE_WWWROOT}';
\$CFG->dataroot  = '${MOODLE_DATAROOT}';
\$CFG->directorypermissions = 02777;

\$CFG->reverseproxy = in_array(strtolower('${MOODLE_REVERSEPROXY}'), ['1', 'true', 'yes', 'on'], true);
\$CFG->sslproxy = in_array(strtolower('${MOODLE_SSLPROXY}'), ['1', 'true', 'yes', 'on'], true);
\$CFG->routerconfigured = in_array(strtolower('${MOODLE_ROUTERCONFIGURED}'), ['1', 'true', 'yes', 'on'], true);

if (!empty(getenv('MOODLE_REDIS_HOST'))) {
  \$CFG->session_handler_class = '\\core\\session\\redis';
  \$CFG->session_redis_host = getenv('MOODLE_REDIS_HOST');
  \$CFG->session_redis_port = getenv('MOODLE_REDIS_PORT') ?: 6379;
  \$CFG->session_redis_database = getenv('MOODLE_REDIS_DB') ?: 0;
  \$CFG->session_redis_prefix = getenv('MOODLE_REDIS_PREFIX') ?: 'moodle_sess_';
}

require_once(__DIR__ . '/lib/setup.php');
PHP
fi

MARKER_FILE="${MOODLE_DATAROOT:-/var/www/moodledata}/.moodle_installed"

run_as_www_data() {
  if command -v su >/dev/null 2>&1 && id -u www-data >/dev/null 2>&1; then
    su -s /bin/sh -c "$*" www-data
  else
    sh -lc "$*"
  fi
}

installer_cmd() {
  if [ -f /var/www/html/admin/cli/install_database.php ]; then
    echo "php /var/www/html/admin/cli/install_database.php"
    return 0
  fi

  if [ -f /var/www/html/admin/cli/install.php ]; then
    echo "php /var/www/html/admin/cli/install.php"
    return 0
  fi

  return 1
}

if [ "${MOODLE_RUN_INSTALL:-0}" = "1" ]; then
  if [ ! -f /var/www/html/config.php ]; then
    echo "config.php is missing; cannot run installer"
    exit 1
  fi

  if [ ! -f "$MARKER_FILE" ]; then
    : "${MOODLE_SITE_FULLNAME:?MOODLE_SITE_FULLNAME is required}"
    : "${MOODLE_SITE_SHORTNAME:?MOODLE_SITE_SHORTNAME is required}"
    : "${MOODLE_ADMIN_USER:?MOODLE_ADMIN_USER is required}"
    : "${MOODLE_ADMIN_PASSWORD:?MOODLE_ADMIN_PASSWORD is required}"
    : "${MOODLE_ADMIN_EMAIL:?MOODLE_ADMIN_EMAIL is required}"

    INSTALLER="$(installer_cmd || true)"
    if [ -z "$INSTALLER" ]; then
      echo "No supported Moodle CLI installer found. Expected one of:"
      echo "  - /var/www/html/admin/cli/install_database.php"
      echo "  - /var/www/html/admin/cli/install.php"
      exit 1
    fi

    if [ "$INSTALLER" = "php /var/www/html/admin/cli/install_database.php" ]; then
      run_as_www_data "$INSTALLER \
        --agree-license \
        --fullname='${MOODLE_SITE_FULLNAME}' \
        --shortname='${MOODLE_SITE_SHORTNAME}' \
        --adminuser='${MOODLE_ADMIN_USER}' \
        --adminpass='${MOODLE_ADMIN_PASSWORD}' \
        --adminemail='${MOODLE_ADMIN_EMAIL}'"
    else
      run_as_www_data "$INSTALLER \
        --non-interactive \
        --agree-license \
        --wwwroot='${MOODLE_WWWROOT}' \
        --dataroot='${MOODLE_DATAROOT}' \
        --dbtype='${MOODLE_DBTYPE}' \
        --dbhost='${MOODLE_DBHOST}' \
        --dbname='${MOODLE_DBNAME}' \
        --dbuser='${MOODLE_DBUSER}' \
        --dbpass='${MOODLE_DBPASSWORD}' \
        --prefix='${MOODLE_DBPREFIX}' \
        --fullname='${MOODLE_SITE_FULLNAME}' \
        --shortname='${MOODLE_SITE_SHORTNAME}' \
        --adminuser='${MOODLE_ADMIN_USER}' \
        --adminpass='${MOODLE_ADMIN_PASSWORD}' \
        --adminemail='${MOODLE_ADMIN_EMAIL}'"
    fi

    mkdir -p "${MOODLE_DATAROOT:-/var/www/moodledata}"
    touch "$MARKER_FILE"
  fi
fi

if [ "${MOODLE_RUN_UPGRADE:-0}" = "1" ]; then
  if [ -f /var/www/html/config.php ] && [ -f "$MARKER_FILE" ]; then
    run_as_www_data "php /var/www/html/admin/cli/upgrade.php --non-interactive"
  fi
fi

chown -R www-data:www-data /var/www/html "${MOODLE_DATAROOT:-/var/www/moodledata}" || true

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec php-fpm
