# encoding: UTF-8
#
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

require 'spec_helper'
require 'mysql_interpolator'

describe 'mysql_tuning resource' do

  def node_setup(node, data)
    unless data[:interpolation].nil?
      node.set['mysql_tuning']['interpolation'] = data[:interpolation]
    end
    node.set['memory']['total'] = system_memory(
      data[:memory].nil? ? 512 * MB : data[:memory]
    )
    node.set['mysql_tuning']['new.cnf'] = {}
  end

  def chef_run(data = {})
    runner = ChefSpec::Runner.new(
        platform: 'ubuntu', version: '12.04',
        step_into: %w(mysql_tuning)
    ) do |node|
      node_setup(node, data)
    end
    runner.converge('mysql_tuning::default')
  end

  def chef_run_tuning(data)
    runner = chef_run(data)
    runner.node['mysql_tuning']['tuning.cnf']
  end

  key_buffer_size_values = {
    65 * MB => [16 * MB, 256 * MB],
    1.1 * GB => [384 * MB, 512 * MB],
    2 * GB => [384 * MB, 512 * MB]
  }

  key_buffer_size_values.each do |memory, range_r|

    context "with #{memory} bytes of memory" do

      %w(proximal linear catmull).each do |interpolation|

        context "with #{interpolation} interpolation type" do

          it 'should set variable values from samples' do
            tuning = chef_run_tuning(
              memory: memory,
              interpolation: interpolation
            )
            expect(tuning['mysqld']['key_buffer_size'])
              .to be_between(range_r[0], range_r[1])
          end # it
        end # context with interpolation type
      end # each do |interpolation|
    end # context with bytes of memory
  end # each do |memory, range_r|

  %w(tuning.cnf logging.cnf new.cnf).each do |cnf|

    it "should create #{cnf} file with mysql_tuning_cnf" do
      expect(chef_run).to create_mysql_tuning_cnf(cnf)
    end

  end # cnf.each

end # describe mysql_tuning resource
