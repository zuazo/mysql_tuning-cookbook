# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Provider:: cnf
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Xabier de Zuazo
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

use_inline_resources if defined?(use_inline_resources)

def complete_service_name(name)
  name.include?('[') ? name : "mysql_service[#{name}]"
end

def default_service_name
  if node['mysql'].nil? || node['mysql']['service_name'].nil?
    'default'
  else
    node['mysql']['service_name']
  end
end

def service_name
  new_resource.service_name(
    complete_service_name(
      if new_resource.service_name.nil?
        default_service_name
      else
        new_resource.service_name
      end
    )
  )
end

def include_dir
  new_resource.include_dir(
    if new_resource.include_dir.nil?
      node['mysql_tuning']['include_dir']
    else
      new_resource.include_dir
    end
  )
end

def values
  new_resource.values(
    if new_resource.values.nil?
      node['mysql_tuning'][new_resource.filename]
    else
      new_resource.values
    end
  )
end

def dynamic?
  new_resource.dynamic(
    if new_resource.dynamic.nil?
      node['mysql_tuning']['dynamic_configuration']
    else
      new_resource.dynamic
    end
  )
end

def mysql_user
  new_resource.mysql_user(
    if new_resource.mysql_user.nil?
      'root'
    else
      new_resource.mysql_user
    end
  )
end

def default_mysql_password
  if node['mysql'].nil? || node['mysql']['server_root_password'].nil?
    'ilikerandompasswords'
  else
    node['mysql']['server_root_password']
  end
end

def mysql_password
  new_resource.mysql_password(
    if new_resource.mysql_password.nil?
      default_mysql_password
    else
      new_resource.mysql_password
    end
  )
end

def default_mysql_port
  if node['mysql'].nil? || node['mysql']['port'].nil?
    '3306'
  else
    node['mysql']['port']
  end
end

def mysql_port
  new_resource.mysql_port(
    if new_resource.mysql_port.nil?
      default_mysql_port
    else
      new_resource.mysql_port
    end
  )
end

def install_mysql_gem
  return unless Gem::Specification.find_all_by_name('mysql').empty?
  mysql2_chef_gem 'default' do
    action :nothing
  end.run_action(:install)
end

def update_configuration_dynamically
  return true unless values.key?('mysqld')
  return false unless dynamic?

  install_mysql_gem
  ::MysqlTuningCookbook::MysqlHelpers.set_variables(
    values['mysqld'],
    mysql_user,
    mysql_password,
    mysql_port
  )
end

def include_mysql_recipe
  # include_recipe is required for notifications to work
  return if node['mysql_tuning']['recipe'].nil?
  puts node['mysql_tuning']['recipe']
  @run_context.include_recipe(node['mysql_tuning']['recipe'])
end

action :create do
  self.class.send(:include, ::MysqlTuningCookbook::CookbookHelpers)

  r = template ::File.join(include_dir, new_resource.filename) do
    cookbook 'mysql_tuning'
    owner 'mysql'
    group 'mysql'
    source 'mysql.cnf.erb'
    variables(
      config: ::MysqlTuningCookbook::MysqlHelpers::Cnf.fix(
        values, node['mysql_tuning']['variables_block_size'],
        node['mysql_tuning']['old_names'], mysql_ver
      )
    )
    only_if { new_resource.persist }
    unless update_configuration_dynamically
      include_mysql_recipe
      notifies :restart, service_name
    end
    action :nothing
  end
  r.run_action(:create)
  new_resource.updated_by_last_action(r.updated_by_last_action?)
end

action :delete do
  include_mysql_recipe
  r = file ::File.join(include_dir, new_resource.file_name) do
    notifies :restart, service_name
    action :nothing
  end
  r.run_action(:delete)
  new_resource.updated_by_last_action(r.updated_by_last_action?)
end
