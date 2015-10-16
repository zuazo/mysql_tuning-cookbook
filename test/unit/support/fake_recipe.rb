# encoding: UTF-8
#
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

require 'chef/node'
require 'cookbook_helpers'
require_relative 'memory_helpers'

# Class to emulate a mysql cookbook version.
class FakeMysqlCookbook
  def version
    '6.1.2'
  end
end

# Class to emulate the current recipe with some helpers
class FakeRecipe < ::Chef::Node
  include ::MysqlTuningCookbook::CookbookHelpers
  include ::MemoryHelpers

  def initialize
    super
    name('node001')
    node = self
    Dir.glob("#{::File.dirname(__FILE__)}/../../../attributes/*.rb") do |f|
      node.from_file(f)
    end
    memory(2 * GB)
  end

  def cookbook_collection
    Mash.new(mysql: FakeMysqlCookbook.new)
  end

  def run_context
    @run_context ||= begin
      Chef::RunContext.new(node, cookbook_collection, nil)
    end
  end

  def memory(value = nil)
    if value.nil?
      node['memory']['total']
    else
      node.automatic['memory']['total'] = system_memory(value)
    end
  end

  def cnf_samples(value = nil)
    if value.nil?
      node['mysql_tuning']['configuration_samples']
    else
      node.default['mysql_tuning']['configuration_samples'] = value
    end
  end

  def interpolation_type(value = nil)
    if value.nil?
      node['mysql_tuning']['interpolation']
    else
      node.default['mysql_tuning']['interpolation'] = value
    end
  end

  def non_interpolated_keys(value = nil)
    if value.nil?
      node['mysql_tuning']['non_interpolated_keys']
    else
      node.default['mysql_tuning']['non_interpolated_keys'] = value
    end
  end

  def system_percentage(value = nil)
    if value.nil?
      node['mysql_tuning']['system_percentage']
    else
      node.default['mysql_tuning']['system_percentage'] = value
    end
  end
end
