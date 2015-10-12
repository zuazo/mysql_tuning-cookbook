#!/usr/bin/env bats

load test_helper

@test "should pass configuration file checking" {
  "${MYSQLD_BIN}" --help
}

@test "should create tuning.cnf file" {
  [ -f "${MYSQL_CONFD_PATH}/tuning.cnf" ]
}

@test "should set key_buffer_size in tuning.cnf" {
  grep \
    -e "key_buffer_size" \
    "${MYSQL_CONFD_PATH}/tuning.cnf"
}

@test "should create logging.cnf file" {
  [ -f "${MYSQL_CONFD_PATH}/logging.cnf" ]
}

@test "should set slow_query_log_file in logging.cnf" {
  grep \
    -e "slow_query_log_file" \
    -e "log_slow_queries" \
    "${MYSQL_CONFD_PATH}/logging.cnf"
}
