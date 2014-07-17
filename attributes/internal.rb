# encoding: UTF-8

self.class.send(:include, ::MysqlTuning::CookbookHelpers)

default['mysql_tuning']['old_names'] = {
  'general_log' => {
    '< 5.1.29' => 'log'
  },
  'slow_query_log' => {
    '< 5.1.12' => nil
  },
  'slow_query_log_file' => {
    '< 5.1.12' => 'log_slow_queries'
  },
  'table_open_cache' => {
    '< 5.1.3' => 'table_cache'
  }
}

default['mysql_tuning']['non_interpolated_keys']['mysqld'] = %w(
  innodb_log_file_size
)

default['mysql_tuning']['variables_block_size'] = {
  binlog_cache_size: IO_SIZE,
  binlog_stmt_cache_size: IO_SIZE,
  innodb_additional_mem_pool_size: 1024,
  innodb_buffer_pool_size: MB,
  innodb_log_buffer_size: 1024,
  innodb_log_file_size: MB,
  key_buffer_size: IO_SIZE,
  key_cache_block_size: 512,
  max_allowed_packet: 1024,
  max_binlog_cache_size: IO_SIZE,
  max_binlog_size: IO_SIZE,
  max_binlog_stmt_cache_size: IO_SIZE,
  max_relay_log_size: IO_SIZE,
  net_buffer_length: 1024,
  query_cache_size: 1024,
  read_buffer_size: IO_SIZE,
  read_buff_size: IO_SIZE,
  myisam_max_sort_file_size: MB,
  myisam_block_size: 1024
}
