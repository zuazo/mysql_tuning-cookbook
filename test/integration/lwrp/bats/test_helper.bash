#!/usr/bin/env bats

setup() {
  if [ -f '/usr/libexec/mysqld' ]
  then
    MYSQLD_BIN='/usr/libexec/mysqld'
  elif [ -f '/usr/local/libexec/mysqld' ]
  then
    MYSQLD_BIN='/usr/local/libexec/mysqld'
  elif [ -f '/usr/local/libexec/mysqld' ]
  then
    MYSQLD_BIN='/usr/local/libexec/mysqld'
  else
    MYSQLD_BIN='mysqld'
  fi

  if [ -d '/etc/mysql-default/conf.d' ]
  then
    MYSQL_CONFD_PATH='/etc/mysql-default/conf.d'
  elif [ -d '/etc/mysql/conf.d' ]
  then
    MYSQL_CONFD_PATH='/etc/mysql/conf.d'
  elif [ -d '/etc/my.cnf.d' ]
  then
    MYSQL_CONFD_PATH='/etc/my.cnf.d'
  elif [ -d '/usr/local/etc/mysql/conf.d' ]
  then
    MYSQL_CONFD_PATH='/usr/local/etc/mysql/conf.d'
  fi
}
