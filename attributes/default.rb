# encoding: UTF-8

self.class.send(:include, ::MysqlTuning::CookbookHelpers)

default['mysql_tuning']['system_percentage'] = 100
default['mysql_tuning']['dynamic_configuration'] = false
default['mysql_tuning']['interpolation'] = 'proximal'
default['mysql_tuning']['recipe'] = nil

default['mysql_tuning']['interpolation_by_variable'] = {}

case node['platform']
when 'fedora'
  default['mysql_tuning']['include_dir'] = '/etc/my.cnf.d'
when 'freebsd'
  default['mysql_tuning']['include_dir'] = '/usr/local/etc/mysql/conf.d'
else
  default['mysql_tuning']['include_dir'] = '/etc/mysql/conf.d'
end

default['mysql_tuning']['mysqld_bin'] =
  case node['platform']
  when 'centos'
    node['platform_version'].to_i >= 7 ?  'mysqld' : '/usr/libexec/mysqld'
  when 'redhat', 'scientific', 'fedora', 'suse', 'amazon'
    '/usr/libexec/mysqld'
  when 'freebsd'
    '/usr/local/libexec/mysqld'
  # when 'debian', 'ubuntu' then
  else
    'mysqld'
  end

default['mysql_tuning']['logging.cnf'] = {
  mysqld: {
    expire_logs_days: 30,
    slow_query_log: 'ON',
    slow_query_log_file: 'slow-query.log'
  }
}

# Calculated from samples
default['mysql_tuning']['tuning.cnf'] = Mash.new
