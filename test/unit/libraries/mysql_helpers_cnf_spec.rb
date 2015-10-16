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

require_relative '../spec_helper'
require_relative '../support/fake_recipe'
# require 'cookbook_helpers'
require 'mysql_helpers'
require 'mysql_helpers_cnf'
# require 'mysql_interpolator'

describe MysqlTuningCookbook::MysqlHelpers::Cnf do
  subject(:node) { FakeRecipe.new.node }

  context '#fix' do
    let(:cnf) do
      { 'mysqld' => {
        'slow_query_log' => 'ON',
        'slow_query_log_file' => 'foo'
      } }
    end

    it 'does not fix conigurations with new versions' do
      expect(described_class.fix(
        cnf,
        node['mysql_tuning']['variables_block_size'],
        node['mysql_tuning']['old_names'],
        '5.5'
      )).to eql(cnf)
    end

    it 'fixes conigurations with old versions' do
      expect(described_class.fix(
        cnf,
        node['mysql_tuning']['variables_block_size'],
        node['mysql_tuning']['old_names'],
        '5.0'
      )).to eql('mysqld' => { 'log_slow_queries' => 'foo' })
    end
  end
end
