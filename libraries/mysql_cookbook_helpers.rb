# encoding: UTF-8

require 'mixlib/shellout'

class MysqlTuning
  # Some MySQL Cookbook Helpers to get MySQL internal package names
  module MysqlCookbookHelpers
    def package_from_helper_library?
      defined?(Opscode::Mysql::Helpers) &&
      Opscode::Mysql::Helpers.respond_to?(:default_version_for) &&
      Opscode::Mysql::Helpers.respond_to?(:package_name_for)
    end

    def package_from_helper_library
      return nil unless package_from_helper_library?
      self.class.include(::Opscode::Mysql::Helpers)
      version = default_version_for(
        node['platform'], node['platform_family'],
        node['platform_version']
      )
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
