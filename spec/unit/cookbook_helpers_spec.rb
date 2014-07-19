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
require 'chef/node'
require 'cookbook_helpers'
require 'mysql_helpers'
require 'mysql_interpolator'

# Class to emulate the current recipe with some helpers
class FakeRecipe < ::Chef::Node
  include ::MysqlTuning::CookbookHelpers
  include ::MemoryHelpers

  def initialize
    super
    name('node001')
    node = self
    Dir.glob("#{::File.dirname(__FILE__)}/../../attributes/*.rb") do |f|
      node.from_file(f)
    end
    memory(2 * GB)
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

describe MysqlTuning::CookbookHelpers do
  subject { FakeRecipe.new }
  let(:cnf_from_samples) do
    subject.cnf_from_samples(
      subject.cnf_samples,
      subject.interpolation_type,
      subject.non_interpolated_keys
    )
  end

  context '#mysql_fix_cnf' do
    let(:cnf) do
      { 'mysqld' => {
        'slow_query_log' => 'ON',
        'slow_query_log_file' => 'foo'
      } }
    end

    it 'should not fix conigurations with new versions' do
      allow(subject).to receive(:mysql_version).and_return('5.5')
      expect(subject.mysql_fix_cnf(cnf))
        .to eql(cnf)
    end

    it 'should fix conigurations with old versions' do
      allow(subject).to receive(:mysql_version).and_return('5.0')
      expect(subject.mysql_fix_cnf(cnf))
        .to eql('mysqld' => { 'log_slow_queries' => 'foo' })
    end

  end

  context '#cnf_from_samples' do

    it 'should not throw any error with default examples' do
      expect { cnf_from_samples }.not_to raise_error
    end

    context 'proximal interpolation' do
      before do
        subject.interpolation_type('proximal')
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 100 } },
          4 * GB => { 'mysqld' => { 'key1' => 200 } }
        )
      end

      it 'should choose the lower sample if below' do
        subject.memory(500 * MB)
        expect(cnf_from_samples['mysqld']['key1']).to eql(100)
      end

      it 'should choose the lower sample if in between' do
        subject.memory(2 * GB)
        expect(cnf_from_samples['mysqld']['key1']).to eql(100)
      end

      it 'should choose the higher sample if above' do
        subject.memory(8 * GB)
        expect(cnf_from_samples['mysqld']['key1']).to eql(200)
      end

    end # context proximal interpolation

    context 'non-proximal interpolation' do
      before do
        allow(subject).to receive(:chef_gem).and_return(subject)
        allow(subject).to receive(:run_action).and_return(subject)
        allow(::Chef::Log).to receive(:warn)

        subject.interpolation_type('linear')
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 100 } },
          4 * GB => { 'mysqld' => { 'key1' => 200 } }
        )
      end

      it 'should use proximal interpolation for lower values' do
        subject.memory(500 * MB)
        expect(cnf_from_samples['mysqld']['key1']).to eql(100)
      end

      it 'should warn when proximal interpolation is used' do
        subject.memory(500 * MB)
        expect(::Chef::Log).to receive(:warn).with(/Memory for MySQL too low/)
        cnf_from_samples['mysqld']['key1']
      end

      it 'should interpolate intermediate values' do
        subject.memory(2 * GB)
        expect(cnf_from_samples['mysqld']['key1']).to eql(133)
      end

      it 'should interpolate higher' do
        subject.memory(8 * GB)
        expect(cnf_from_samples['mysqld']['key1']).to eql(333)
      end

      it 'should interpolate with system_percentage' do
        subject.memory(8 * GB)
        subject.system_percentage(25)
        expect(cnf_from_samples['mysqld']['key1']).to eql(133)
      end

      it 'should not interpolate non-integer values' do
        subject.memory(2 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 'value1' } },
          4 * GB => { 'mysqld' => { 'key1' => 'value2' } }
        )
        expect(cnf_from_samples['mysqld']['key1']).to eql('value1')
      end

      it 'should not interpolate non-interpolated keys' do
        subject.memory(2 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 100 } },
          4 * GB => { 'mysqld' => { 'key1' => 200 } }
        )
        subject.non_interpolated_keys(mysqld: %w(key1))
        expect(cnf_from_samples['mysqld']['key1']).to eql(100)
      end

      it 'should interpolate mysql integer values' do
        subject.memory(2 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => '100M' } },
          4 * GB => { 'mysqld' => { 'key1' => '200M' } }
        )
        expect(cnf_from_samples['mysqld']['key1']).to eql(139_810_133)
      end

      it 'should interpolate without rounding to block size' do
        subject.memory(2 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => '100M' } },
          4 * GB => { 'mysqld' => { 'key1' => '200M' } }
        )
        expect(cnf_from_samples['mysqld']['key1'] % 1024)
          .not_to be_zero
      end

      it 'should interpolate rounding to block size' do
        subject.memory(1 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'innodb_log_buffer_size' => '100M' } },
          4 * GB => { 'mysqld' => { 'innodb_log_buffer_size' => '200M' } }
        )
        expect(cnf_from_samples['mysqld']['innodb_log_buffer_size'] % 1024)
          .to be_zero
      end

      it 'should set keys set for next two higher memory values' do
        subject.memory(1.1 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 100 } },
          2 * GB => { 'mysqld' => { 'key2' => 100 } },
          3 * GB => { 'mysqld' => { 'key3' => 100 } },
          4 * GB => { 'mysqld' => { 'key4' => 100 } }
        )
        expect(cnf_from_samples['mysqld'].key?('key3')).to be true
      end

      it 'should ignore keys set for far higher memory values' do
        subject.memory(1.1 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 100 } },
          2 * GB => { 'mysqld' => { 'key2' => 100 } },
          3 * GB => { 'mysqld' => { 'key3' => 100 } },
          4 * GB => { 'mysqld' => { 'key4' => 100 } }
        )
        expect(cnf_from_samples['mysqld'].key?('key4')).to be false
      end

      it 'should warn when there not enough values' do
        # cubic requires 3 points
        subject.interpolation_type('cubic')
        subject.memory(1.1 * GB)
        subject.cnf_samples(
          1 * GB => { 'mysqld' => { 'key1' => 100 } },
          4 * GB => { 'mysqld' => { 'key1' => 200 } }
        )
        expect(::Chef::Log).to receive(:warn)
          .with(/Cannot interpolate .* Not enough data points/)
        expect(cnf_from_samples['mysqld']['key1']).to eql(100)
      end

    end

  end
end
