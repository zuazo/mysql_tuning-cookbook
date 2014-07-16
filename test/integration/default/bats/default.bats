#!/usr/bin/env bats

@test "mysqld should be runing" {
  ps axu | grep mysql[d]
}

@test "should pass configuration file checking" {
  mysql --help
}

@test "should create tuning.cnf file" {
  [ -f "/etc/mysql/conf.d/tuning.cnf" ]
}

@test "should set key_buffer_size in tuning.cnf" {
  grep "key_buffer_size" /etc/mysql/conf.d/tuning.cnf
}

@test "should create logging.cnf file" {
  [ -f "/etc/mysql/conf.d/logging.cnf" ]
}

@test "should set key_buffer_size in logging.cnf" {
  grep "slow_query_log" /etc/mysql/conf.d/logging.cnf
}
