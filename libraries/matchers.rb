# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Library:: matchers
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

if defined?(ChefSpec)

  if ChefSpec.respond_to?(:define_matcher)
    # ChefSpec >= 4.1
    ChefSpec.define_matcher :mysql_tuning
    ChefSpec.define_matcher :mysql_tuning_cnf
  elsif defined?(ChefSpec::Runner) &&
        ChefSpec::Runner.respond_to?(:define_runner_method)
    # ChefSpec < 4.1
    ChefSpec::Runner.define_runner_method :mysql_tuning
    ChefSpec::Runner.define_runner_method :mysql_tuning_cnf
  end

  def create_mysql_tuning(name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_tuning,
      :create,
      name
    )
  end

  def delete_mysql_tuning(name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_tuning,
      :delete,
      name
    )
  end

  def create_mysql_tuning_cnf(filename)
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_tuning_cnf,
      :create,
      filename
    )
  end

  def delete_mysql_tuning_cnf(filename)
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_tuning_cnf,
      :delete,
      filename
    )
  end

end
