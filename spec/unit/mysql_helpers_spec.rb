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
require 'mysql_helpers'

describe MysqlTuning::MysqlHelpers do

  context '#numeric?' do

    [5, 5.0, '5', '5G', '5M', '5K', '5B'].each do |value|
      it "returns true for #{value.inspect}" do
        expect(described_class.numeric?(value)).to be true
      end
    end

    ['NAN', true, false].each do |value|
      it "returns false for #{value.inspect}" do
        expect(described_class.numeric?(value)).to be false
      end
    end

  end

  context '#mysql2num' do

    {
      5 => 5,
      5.0 => 5,
      '5' => 5,
      '5B' => 5,
      '5K' => 5 * KB,
      '5M' => 5 * MB,
      '5G' => 5 * GB
    }.each do |value, numeric|
      it "returns #{numeric.inspect} for #{value.inspect}" do
        expect(described_class.mysql2num(value)).to eql(numeric)
      end
    end

  end

  context '#set_variables' do
    before do
      allow(described_class).to receive(:connect).and_return('db')
      allow(described_class).to receive(:disconnect)
      @variables = {
        'var1' => 100,
        'var2' => 200,
        'var3' => 300
      }.to_a
    end
    def variable_returns(returns)
      @variables.each do |key, value|
        allow(described_class).to receive(:set_variable).with('db', key, value)
          .and_return(returns.shift)
      end
    end

    it 'should return true if all variables has been set' do
      variable_returns([true, true, true])
      expect(described_class.set_variables(
        @variables, 'user', 'password', 'port'
      )).to equal(true)
    end

    it 'should return false if no variables has been set' do
      variable_returns([false, false, false])
      expect(described_class.set_variables(
        @variables, 'user', 'password', 'port'
      )).to equal(false)
    end

    it 'should return false if one variable has not been set' do
      variable_returns([true, false, true])
      expect(described_class.set_variables(
        @variables, 'user', 'password', 'port'
      )).to equal(false)
    end

    it 'should return false if the last variable has not been set' do
      variable_returns([true, true, false])
      expect(described_class.set_variables(
        @variables, 'user', 'password', 'port'
      )).to equal(false)
    end

  end

end
