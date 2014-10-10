#!/usr/bin/env bats

@test "mysqld should be runing" {
  ps axu | grep mysql[d]
}

@test "should pass configuration file checking" {
  if [ -f /usr/libexec/mysqld ]
  then
    MYSQLD=/usr/libexec/mysqld
  elif [ -f /usr/local/libexec/mysqld ]
  then
    MYSQLD=/usr/local/libexec/mysqld
  else
    MYSQLD=mysqld
  fi
  $MYSQLD --help
}

@test "should create tuning.cnf file" {
  [ -f /etc/mysql/conf.d/tuning.cnf ] || [ -f /etc/my.cnf.d/tuning.cnf ] || [ -f /usr/local/etc/mysql/conf.d/tuning.cnf ]
}

@test "should set key_buffer_size in tuning.cnf" {
  if [ -f /etc/my.cnf.d/tuning.cnf ]
  then
    CNF=/etc/my.cnf.d/tuning.cnf
  elif [ -f /usr/local/etc/mysql/conf.d/tuning.cnf ]
  then
    CNF=/usr/local/etc/mysql/conf.d/tuning.cnf
  else
    CNF=/etc/mysql/conf.d/tuning.cnf
  fi
  grep "key_buffer_size" $CNF
}

@test "should create logging.cnf file" {
  [ -f /etc/mysql/conf.d/logging.cnf ] || [ -f /etc/my.cnf.d/logging.cnf ] || [ -f /usr/local/etc/mysql/conf.d/logging.cnf ]
}

@test "should set slow_query_log_file in logging.cnf" {
  if [ -f /etc/my.cnf.d/logging.cnf ]
  then
    CNF=/etc/my.cnf.d/logging.cnf
  elif [ -f /usr/local/etc/mysql/conf.d/logging.cnf ]
  then
    CNF=/usr/local/etc/mysql/conf.d/logging.cnf
  else
    CNF=/etc/mysql/conf.d/logging.cnf
  fi
  grep -e "slow_query_log_file" -e "log_slow_queries" $CNF
}
