# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Library:: mysql_cookbook_helpers
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

require 'mixlib/shellout'

class MysqlTuningCookbook
  # Some MySQL Cookbook Helpers to get MySQL internal package names.
  module MysqlCookbookHelpers
    def package_from_mysql_service?
      defined?(::Chef::Provider::MysqlClient) &&
        ::Chef::Provider::MysqlClient.method_defined?(:client_package)
    end

    def package_from_mysql_service
      return nil unless package_from_mysql_service?
      r = ::Chef::Resource::MysqlClient.new(
        'get mysql package name (monkey-patch)', run_context
      )
      r.action(:nothing)
      p = ::Chef::Provider::MysqlClient.new(r, run_context)
      [p.client_package].flatten.first
    end

    def parsed_package_name
      @parsed_package_name ||= package_from_mysql_service
    end
  end
end
