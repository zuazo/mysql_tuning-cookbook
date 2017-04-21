# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning_test
# Recipe:: lwrp
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

root_password = 'r00t_p4ssw0rd'

node.default['mysql_tuning']['dynamic_configuration'] = true

mysql_service 'default' do
  initial_root_password root_password
  action [:create, :start]
end

mysql_tuning 'default' do
  mysql_user 'root'
  mysql_password root_password
end

# Required for integration tests:
include_recipe 'netstat'
