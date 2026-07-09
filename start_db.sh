#!/bin/bash
# start_db.sh — käivitab MariaDB serveri (TCP + socket)
if pgrep -x mariadbd > /dev/null; then
  echo "MariaDB juba töötab"
  exit 0
fi
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld 2>/dev/null || true
setsid mariadbd --user=root \
  --datadir=/var/lib/mysql \
  --bind-address=0.0.0.0 \
  --port=3306 \
  --skip-networking=0 \
  --log-error=/tmp/mariadb_error.log \
  > /tmp/mariadb_out.log 2>&1 < /dev/null &
# oota kuni socket + port valmis
for i in $(seq 1 30); do
  if mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then
    echo "MariaDB käivitatud (socket valmis)"
    break
  fi
  sleep 1
done
