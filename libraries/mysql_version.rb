# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Library:: mysql_version
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

require 'mixlib/shellout'

class MysqlTuningCookbook
  # Some MySQL Helpers to get mysql version
  module MysqlVersion
    def self.get(bin = 'mysqld')
      cmd = run_command("#{bin} --version")
      parse_mysql_version(cmd.split("\n")[0])
    end

    def self.run_command(cmd)
      result = Mixlib::ShellOut.new(cmd).run_command
      result.error!
      result.stdout
    end

    def self.parse_mysql_version(stdout)
      case stdout
      when / +Ver +[0-9][0-9.]+ Distrib ([0-9][0-9.]*)[^0-9.]/
        Regexp.last_match[1]
      when / +Ver +([0-9][0-9.]*)[^0-9.]/
        Regexp.last_match[1]
      else
        raise "Unknown MySQL version: #{stdout}"
      end
    end
  end
end
