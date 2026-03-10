#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_DEFAULT="${SCRIPT_DIR}/.env"
ENV_FILE="${ENV_FILE:-${ENV_FILE_DEFAULT}}"

if [ -f "${ENV_FILE}" ]; then
  set -a
  . "${ENV_FILE}"
  set +a
fi

COMPOSE=(docker compose --project-directory "${SCRIPT_DIR}")
if [ -f "${ENV_FILE}" ]; then
  COMPOSE+=(--env-file "${ENV_FILE}")
fi

DUMP_FILE_DEFAULT="${SCRIPT_DIR}/../old/moodle-database.backup.20260311.sql"
DUMP_FILE="${1:-${DUMP_FILE_DEFAULT}}"

if [ ! -f "${DUMP_FILE}" ]; then
  echo "Dump file not found: ${DUMP_FILE}" >&2
  echo "Usage: $0 [/absolute/or/relative/path/to/dump.sql]" >&2
  exit 1
fi

echo "Waiting for MySQL to be ready..."
"${COMPOSE[@]}" exec -T db sh -lc '
  for i in $(seq 1 60); do
    mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" --silent >/dev/null 2>&1 && exit 0
    sleep 1
  done
  echo "MySQL did not become ready in time" >&2
  exit 1
'

echo "Dropping and recreating database..."
"${COMPOSE[@]}" exec -T db sh -lc '
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
  DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`;
  CREATE DATABASE \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  "
'

echo "Importing dump: ${DUMP_FILE}"
cat "${DUMP_FILE}" | "${COMPOSE[@]}" exec -T db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'

echo "Sanity checks..."
"${COMPOSE[@]}" exec -T db sh -lc '
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -e "
  SELECT COUNT(*) AS users_count FROM mdl_user;
  SELECT COUNT(*) AS courses_count FROM mdl_course;
  SELECT COUNT(*) AS categories_count FROM mdl_course_categories;
  SELECT COUNT(*) AS missing_category_refs
    FROM mdl_course c
    LEFT JOIN mdl_course_categories cc ON cc.id=c.category
   WHERE c.category IS NOT NULL AND cc.id IS NULL;
  "
'

echo "Done."