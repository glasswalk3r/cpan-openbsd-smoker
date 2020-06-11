#!/usr/local/bin/bash

root_pass=$1

set -e

echo -n 'Configuring MariaDB for testing with CPAN modules...'

/usr/local/bin/mysql_install_db
/usr/sbin/rcctl enable mysqld
sed -i -E 's/^(log-bin=)/#\\1/' /etc/my.cnf
sed -i -E 's/^(binlog_format=)/#\\1/' /etc/my.cnf
/usr/sbin/rcctl start mysqld
sed -i -f /tmp/mysql-perf.txt /etc/my.cnf
/usr/sbin/rcctl restart mysqld

echo 'Done'

echo -n 'Executing equivalent configuration provided by mysql_secure_installation...'
# commands from https://raw.githubusercontent.com/MariaDB/server/10.4/scripts/mysql_secure_installation.sh
mysql --user=root <<_EOF_
  UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('${root_pass}')) WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  FLUSH PRIVILEGES;
_EOF_

echo 'Done'
