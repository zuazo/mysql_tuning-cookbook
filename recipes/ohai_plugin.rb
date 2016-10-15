# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Recipe:: ohai_plugin
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

Chef::Recipe.send(:include, ::MysqlTuningCookbook::MysqlCookbookHelpers)

def ohai7?
  Gem::Requirement.new('>= 7').satisfied_by?(Gem::Version.new(Ohai::VERSION))
end

source_dir = ohai7? ? 'ohai7_plugins' : 'ohai_plugins'
package_name = parsed_package_name

# dummy resource to be able to notify reload action to the ohai plugin
ohai 'mysql' do
  plugin 'mysql'
  action :nothing
end

ruby_block 'ohai plugin reload subscriber' do
  block {}
  subscribes :create, "package[#{package_name}]", :immediately
  notifies :create, 'ohai_plugin[mysql]', :immediately
  action :nothing
end

ohai_plugin 'mysql' do
  name 'mysql'
  source_file "#{source_dir}/mysql.rb.erb"
  resource :template
  variables mysql_bin: node['mysql_tuning']['mysqld_bin']
end
