# encoding: UTF-8

self.class.send(:include, ::MysqlTuning::CookbookHelpers)

default['mysql_tuning']['system_percentage'] = 100

default['mysql_tuning']['dynamic_configuration'] = false

default['mysql_tuning']['interpolation'] = 'proximal'

default['mysql_tuning']['non_interpolated_keys']['mysqld'] = %w(
  innodb_log_file_size
)

default['mysql_tuning']['directory'] = '/etc/mysql/conf.d'

default['mysql_tuning']['logging.cnf'] = {
  mysqld: {
    expire_logs_days: 30,
    slow_query_log: 'ON',
    slow_query_log_file: 'slow-query.log'
  }
}

# Calculated from samples
default['mysql_tuning']['tuning.cnf'] = {}
