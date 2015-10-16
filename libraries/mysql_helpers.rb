# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Library:: mysql_helpers
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

class MysqlTuningCookbook
  # Some generic helpers related with MySQL
  class MysqlHelpers
    def self.numeric?(num)
      case num
      when Numeric then true
      when /^[0-9]+[GMKB]?$/ then true
      else
        false
      end
    end

    def self.mysql2num(num)
      return num.to_i unless num =~ /^([0-9]+)([GMKB])$/
      base = case Regexp.last_match[2]
             when 'G' then 1_073_741_824
             when 'M' then 1_048_576
             when 'K' then 1024
             when 'B' then 1
             end
      Regexp.last_match[1].to_i * base
    end

    def self.num2mysql(num)
      if num > 10_737_418_240
        "#{(num / 1_073_741_824).floor}G"
      elsif num > 10_485_760
        "#{(num / 1_048_576).floor}M"
      elsif num > 10_240
        "#{(num / 1024).floor}K"
      else
        num.to_s
      end
    end

    # Returns true if all variables has been set correctly
    def self.set_variables(vars, user, password, port)
      db = connect(user, password, port.to_i)

      result = vars.reduce(true) do |r, (key, value)|
        return false unless r
        set_variable(db, key, value)
      end

      disconnect(db)
      result
    end

    # private

    def self.connect(user, password, port)
      require 'mysql2'
      # TODO: use the socket?
      Mysql2::Client.new(
        host: '127.0.0.1',
        username: user,
        password: password,
        port: port
      )
    end
    private_class_method :connect

    def self.disconnect(db)
      db.close
    rescue
      nil
    end
    private_class_method :disconnect

    def self.variable_exists?(db, name)
      value = db.query("SHOW GLOBAL VARIABLES LIKE '#{db.escape(name)}'")
      value.count > 0
    end
    private_class_method :variable_exists?

    def self.get_variable(db, name)
      value = db.query("SHOW GLOBAL VARIABLES LIKE '#{db.escape(name)}'")
      value.count > 0 ? value.first.values[1] : nil
    end
    private_class_method :get_variable

    def self.set_variable_query(db, name, value)
      value = mysql2num(value) if numeric?(value)
      db.query("SET GLOBAL #{name} = #{value}")
      Chef::Log.info("Changed MySQL #{name.inspect} variable "\
        "to #{value.inspect} dynamically")
      true
    rescue Mysql2::Error => e
      Chef::Log.info("MySQL #{name.inspect} variable cannot be changed "\
        "to #{value.inspect} dynamically: #{e.message}")
      false
    end
    private_class_method :set_variable_query

    def self.set_variable(db, name, value)
      return false unless variable_exists?(db, name)
      return true if get_variable(db, name).to_s == value.to_s
      set_variable_query(db, name, value)
    end
    private_class_method :set_variable
  end
end
