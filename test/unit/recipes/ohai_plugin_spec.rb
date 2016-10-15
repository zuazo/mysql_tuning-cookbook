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

describe 'mysql_tuning::ohai_plugin' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'creates ohai dummy resource' do
    resource = chef_run.ohai('mysql')
    expect(resource).to do_nothing
  end

  it 'creates ohai plugin reload subscriber resource' do
    resource = chef_run.ruby_block('ohai plugin reload subscriber')
    expect(resource).to do_nothing
  end

  it 'creates ohai mysql plugin' do
    expect(chef_run).to create_ohai_plugin('mysql')
      .with_resource(:template)
  end

  context 'ohai plugin reload subscriber resource' do
    let(:resource) { chef_run.ruby_block('ohai plugin reload subscriber') }
    let(:mysql_package) { 'mysql_package' }

    xit 'subscribes to package installation'

    it 'notifies mysql ohai plugin to create' do
      expect(resource).to notify('ohai_plugin[mysql]').to(:create).immediately
    end
  end

  context 'with Ohai 6' do
    before do
      stub_const('Ohai::VERSION', '6.24.2')
    end

    it 'uses the template from plugins/' do
      expect(chef_run).to create_ohai_plugin('mysql')
        .with_source_file('ohai_plugins/mysql.rb.erb')
    end
  end # context with Ohai 6

  context 'with Ohai 7' do
    before do
      stub_const('Ohai::VERSION', '7.0.0')
    end

    it 'uses the template from plugins7/' do
      expect(chef_run).to create_ohai_plugin('mysql')
        .with_source_file('ohai7_plugins/mysql.rb.erb')
    end
  end # context with Ohai 7
end
