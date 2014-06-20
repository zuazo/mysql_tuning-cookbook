#
# Cookbook Name:: mysql_tuning
# Recipe:: default
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

configs = node['mysql_tuning'].keys.select { |i| i[/\.cnf$/] }

configs.each do |config|
  template "/etc/mysql/conf.d/#{config}" do
    owner 'mysql'
    owner 'mysql'      
    source 'mysql.cnf.erb'
    variables({
      :config => node['mysql_tuning'][config]
    })
    notifies :restart, "mysql_service[#{node['mysql_tuning']['service_name']}]"
  end
end
