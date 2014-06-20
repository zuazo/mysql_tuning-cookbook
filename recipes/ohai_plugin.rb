#
# Cookbook Name:: mysql_tuning
# Recipe:: ohai_plugin
#
# Copyright 2014, Onddo Labs, Sl.
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

def ohai7?
  Gem::Requirement.new('>= 7').satisfied_by?(Gem::Version.new(Ohai::VERSION))
end

source_dir = ohai7? ? 'ohai7_plugins' : 'ohai_plugins'

Chef::Recipe.send(:include, ::Opscode::Mysql::Helpers)

version = default_version_for(
  node['platform'],
  node['platform_family'],
  node['platform_version']
)

package_name = package_name_for(
  node['platform'],
  node['platform_family'],
  node['platform_version'],
  version
)

ohai 'reload_mysql' do
  plugin 'mysql'
  action :nothing
  subscribes :reload, "package[#{package_name}]", :immediately
end

cookbook_file "#{node['ohai']['plugin_path']}/mysql.rb" do
  source "#{source_dir}/mysql.rb"
  owner 'root'
  group 'root'
  mode '0755'
  notifies :reload, 'ohai[reload_mysql]', :immediately
end

include_recipe 'ohai::default'
