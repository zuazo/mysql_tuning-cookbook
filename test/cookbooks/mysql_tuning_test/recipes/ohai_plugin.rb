# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning_test
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

# Silence extraneous stderr from ohai
# "INFO: The plugin path /etc/chef/ohai/plugins does not exist. Skipping..."
directory '/etc/chef/ohai/plugins' do
  recursive true
end

include_recipe 'mysql_tuning_test::mysql_service'
include_recipe 'mysql_tuning::ohai_plugin'
