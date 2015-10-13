# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Attributes:: samples
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

self.class.send(:include, ::MysqlTuningCookbook::CookbookHelpers)

# 45M <= RAM <= 64M (small)
default['mysql_tuning']['configuration_samples'][45 * MB] = {
  mysqld: {
    key_buffer_size: '16K',
    table_open_cache: 4,
    sort_buffer_size: '64K',
    read_buffer_size: '256K',
    read_rnd_buffer_size: '256K',
    net_buffer_length: '2K',
    myisam_max_sort_file_size: '2G',
    thread_stack: '64K',
    query_cache_size: '8M',
    max_allowed_packet: '1M',
    thread_cache_size: 4,
    innodb_buffer_pool_size: '16M',
    innodb_additional_mem_pool_size: '2M',
    innodb_lock_wait_timeout: 50
  },
  mysqldump: {
    quick: true,
    max_allowed_packet: '64M'
  },
  mysql: {
    'no-auto-rehash' => true
  },
  myisamchk: {
    key_buffer_size: '8M',
    sort_buffer_size: '8M'
  },
  mysqlhotcopy: {
    'interactive-timeout' => true
  }
}

# 64M < RAM < 512M (medium)
default['mysql_tuning']['configuration_samples'][64 * MB] = {
  mysqld: {
    key_buffer_size: '16M',
    table_open_cache: 64,
    sort_buffer_size: '512K',
    read_rnd_buffer_size: '512K',
    net_buffer_length: '8K',
    thread_stack: '256K'
  },
  myisamchk: {
    key_buffer_size: '20M',
    sort_buffer_size: '20M',
    read_buffer: '2M',
    write_buffer: '2M'
  }
}

# 512M < RAM < 1G (large)
default['mysql_tuning']['configuration_samples'][512 * MB] = {
  mysqld: {
    key_buffer_size: '256M',
    table_open_cache: 256,
    sort_buffer_size: '1M',
    read_buffer_size: '1M',
    read_rnd_buffer_size: '4M',
    net_buffer_length: '16K',
    myisam_sort_buffer_size: '64M',
    query_cache_size: '16M',
    innodb_buffer_pool_size: '256M',
    innodb_additional_mem_pool_size: '20M',
    # innodb_log_file_size: '64M'
  },
  myisamchk: {
    key_buffer_size: '128M',
    sort_buffer_size: '128M'
  }
}

# 1G <= RAM < 4G (huge)
# TODO: ibdata value ?
default['mysql_tuning']['configuration_samples'][1 * GB] = {
  mysqld: {
    key_buffer_size: '384M',
    table_open_cache: 512,
    sort_buffer_size: '2M',
    read_buffer_size: '2M',
    read_rnd_buffer_size: '8M',
    query_cache_size: '32M',
    innodb_buffer_pool_size: '384M',
    # innodb_log_file_size: '100M'
  },
  myisamchk: {
    key_buffer_size: '256M',
    sort_buffer_size: '256M'
  }
}

# 4G <= RAM (heavy)
default['mysql_tuning']['configuration_samples'][4 * GB] = {
  mysqld: {
    key_buffer_size: '512M',
    max_allowed_packet: '16M',
    table_open_cache: 2048,
    sort_buffer_size: '8M',
    read_rnd_buffer_size: '16M',
    join_buffer_size: '8M',
    myisam_sort_buffer_size: '128M',
    bulk_insert_buffer_size: '64M',
    myisam_max_sort_file_size: '10G',
    thread_stack: '192K',
    query_cache_size: '64M',
    query_cache_limit: '2M',
    binlog_cache_size: '1M',
    innodb_buffer_pool_size: '2G',
    innodb_additional_mem_pool_size: '16M',
    # innodb_log_file_size: '256M',
    innodb_log_buffer_size: '8M',
    innodb_log_files_in_group: 3,
    innodb_lock_wait_timeout: 120,
    innodb_write_io_threads: 8,
    innodb_read_io_threads: 8,
    # :innodb_thread_concurrency: 16,
    innodb_max_dirty_pages_pct: 90,
    max_connections: 100,
    max_connect_errors: 10,
    max_heap_table_size: '64M',
    tmp_table_size: '64M'
  },
  myisamchk: {
    key_buffer_size: '512M',
    sort_buffer_size: '512M',
    read_buffer: '8M',
    write_buffer: '8M'
  },
  mysqld_safe: {
    'open-files-limit' => 8192
  }
}
