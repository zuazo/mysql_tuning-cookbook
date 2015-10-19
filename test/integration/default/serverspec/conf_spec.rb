# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Xabier de Zuazo
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

require 'spec_helper'

mysql_bins = %w(
  /usr/libexec/mysqld
  /usr/local/libexec/mysqld
  /usr/sbin/mysqld
)

conf_dirs = %w(
  /etc/mysql-default/conf.d
  /etc/mysql/conf.d
  /etc/my.cnf.d
  /usr/local/etc/mysql/conf.d
)

mysql_bin = mysql_bins.reverse.reduce('mysql') do |memo, path|
  File.exist?(path) ? path : memo
end

conf_dir = conf_dirs.reverse.reduce(conf_dirs.first) do |memo, path|
  File.directory?(path) ? path : memo
end

describe 'Checking MySQL configuration' do
  describe(
    command("su -l nobody -s /bin/sh -c '#{mysql_bin} --verbose --help'")
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'Usage:' }
  end
end

describe 'MySQL configuration files' do
  describe file(conf_dir) do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'mysql' }
    it { should be_grouped_into 'mysql' }
  end

  describe file(::File.join(conf_dir, 'tuning.cnf')) do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'mysql' }
    it { should be_grouped_into 'mysql' }
    its(:content) { should contain 'key_buffer_size' }
  end

  describe file(::File.join(conf_dir, 'logging.cnf')) do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'mysql' }
    it { should be_grouped_into 'mysql' }
    its(:content) { should match(/slow_query_log_file|log_slow_queries/) }
  end
end
