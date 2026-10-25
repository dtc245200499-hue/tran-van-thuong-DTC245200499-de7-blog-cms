#!/bin/sh
(
set -eu
exporter_password="$(cat /run/secrets/exporter_password)"
case "$exporter_password" in *[!a-f0-9]*|'') exit 1;; esac
MYSQL_PWD="$(cat /run/secrets/db_root_password)" mysql -uroot <<SQL
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '$exporter_password' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
SQL
)
