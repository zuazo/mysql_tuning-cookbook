# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Library:: mysql_cookbook_helpers
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
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
  # Some MySQL Cookbook Helpers to get MySQL internal package names
  module MysqlCookbookHelpers
    def package_from_helper_library?
      defined?(Opscode::Mysql::Helpers) &&
        Opscode::Mysql::Helpers.respond_to?(:default_version_for) &&
        Opscode::Mysql::Helpers.respond_to?(:package_name_for)
    end

    def package_version_from_helper_library
      default_version_for(
        node['platform'], node['platform_family'],
        node['platform_version']
      )
    end

    def package_from_helper_library
      return nil unless package_from_helper_library?
      self.class.include(::Opscode::Mysql::Helpers)
      version = package_version_from_helper_library
      package_name_for(
        node['platform'], node['platform_family'],
        node['platform_version'], version
      )
    end

    def package_from_mysql_service?
      defined?(Chef::MysqlService) &&
        Chef::MysqlService.respond_to?(:parsed_package_name)
    end

    def package_from_mysql_service
      return nil unless package_from_mysql_service?
      mysql_service 'get mysql package name (monkey-patch)' do
        action :nothing
      end.parsed_package_name
    end

    def parsed_package_name
      package_from_mysql_service ||
        package_from_helper_library
    end
  end
end
