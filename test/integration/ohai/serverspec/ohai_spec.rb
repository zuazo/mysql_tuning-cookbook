# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Xabier de Zuazo
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

VERSION_REGEXP = /^[0-9]+\.[0-9]+\.[0-9]+$/
PLUGINS_DIR = '/tmp/kitchen/ohai/plugins'.freeze

o = Ohai::System.new(plugin_path: PLUGINS_DIR)
o.all_plugins
OHAI = o.data

describe 'Ohai plugin' do
  it 'reads MySQL version' do
    expect(OHAI['mysql']['installed_version']).to match VERSION_REGEXP
  end
end
