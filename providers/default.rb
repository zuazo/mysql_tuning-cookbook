# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Provider:: default
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

use_inline_resources if defined?(use_inline_resources)

def interpolation
  new_resource.interpolation(
    if new_resource.interpolation.nil?
      node['mysql_tuning']['interpolation']
    else
      new_resource.interpolation
    end
  )
end

def interpolation_by_variable
  new_resource.interpolation_by_variable(
    if new_resource.interpolation_by_variable.nil?
      node['mysql_tuning']['interpolation_by_variable']
    else
      new_resource.interpolation_by_variable
    end
  )
end

def configuration_samples
  new_resource.configuration_samples(
    if new_resource.configuration_samples.nil?
      node['mysql_tuning']['configuration_samples']
    else
      new_resource.configuration_samples
    end
  )
end

def configs
  node['mysql_tuning'].keys.select { |i| i[/\.cnf$/] }
end

action :create do
  self.class.send(:include, ::MysqlTuningCookbook::CookbookHelpers)

  # Avoid interpolating already defined configuration values
  non_interpolated_keys =
    node['mysql_tuning']['tuning.cnf'].each_with_object({}) do |(group, cnf), r|
      r[group] = cnf.keys
    end
  Chef::Mixin::DeepMerge.deep_merge!(
    non_interpolated_keys,
    node['mysql_tuning']['non_interpolated_keys']
  )

  # Interpolate configuration values
  tuning_cnf = cnf_from_samples(
    configuration_samples,
    interpolation,
    non_interpolated_keys,
    interpolation_by_variable
  )
  node.default['mysql_tuning']['tuning.cnf'] =
    Chef::Mixin::DeepMerge.hash_only_merge(
      tuning_cnf,
      node['mysql_tuning']['tuning.cnf']
    )

  new_resource.updated_by_last_action(false)
  configs.each do |config|
    r = mysql_tuning_cnf config do
      service_name new_resource.service_name
      include_dir new_resource.include_dir unless new_resource.include_dir.nil?
      mysql_user new_resource.mysql_user unless new_resource.mysql_user.nil?
      unless new_resource.mysql_password.nil?
        mysql_password new_resource.mysql_password
      end
      mysql_port new_resource.mysql_port unless new_resource.mysql_port.nil?
      action :nothing
    end
    r.run_action(:create)
    new_resource.updated_by_last_action(true) if r.updated_by_last_action?
  end
end

action :delete do
  new_resource.updated_by_last_action(false)
  configs.each do |config|
    r = mysql_tuning_cnf config do
      service_name new_resource.service_name
      include_dir new_resource.include_dir
      mysql_user new_resource.mysql_user # not used on delete
      mysql_password new_resource.mysql_password
      mysql_port new_resource.mysql_port
      action :nothing
    end
    r.run_action(:delete)
    new_resource.updated_by_last_action(true) if r.updated_by_last_action?
  end
end
