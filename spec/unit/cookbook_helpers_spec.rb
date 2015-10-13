# encoding: UTF-8
#
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

require 'spec_helper'
require 'support/fake_recipe'
require 'cookbook_helpers'
require 'mysql_version'
require 'mysql_helpers'
require 'mysql_helpers_cnf'
require 'mysql_interpolator'

describe MysqlTuningCookbook::CookbookHelpers do
  subject { FakeRecipe.new }
  let(:cnf_from_samples) do
    subject.cnf_from_samples(
      subject.cnf_samples,
      subject.interpolation_type,
      subject.non_interpolated_keys
    )
  end
  let(:my_shell_out) { instance_double('Mixlib::ShellOut') }
  let(:my_version_stdout) do
    'mysql  Ver 14.12 Distrib 5.0.95, for redhat-linux-gnu (x86_64) using '\
    'readline 5.1'
  end
  before do
    allow(Mixlib::ShellOut).to receive(:new)
      .with('mysqld --version').and_return(my_shell_out)
    allow(my_shell_out).to receive(:run_command).and_return(my_shell_out)
    allow(my_shell_out).to receive(:error!)
    allow(my_shell_out).to receive(:stdout).and_return(my_version_stdout)
  end

  context '#mysql_cookbook_version' do
    it 'returns the mysql cookbook version' do
      expect(subject.mysql_cookbook_version)
        .to match(/^[0-9]+\.[0-9]+\.[0-9]+$/)
    end
  end

  context '#mysql_cookbook_version_major' do
    it 'returns the mysql cookbook major version' do
      expect(subject.mysql_cookbook_version_major).to be_a(Integer)
    end
  end

  context '#mysql_ver' do
    {
      centos5: [
        '5.0.95',
        'mysql  Ver 14.12 Distrib 5.0.95, for redhat-linux-gnu (x86_64) using '\
        'readline 5.1'
      ],
      centos6: [
        '5.1.73',
        '/usr/libexec/mysqld  Ver 5.1.73 for redhat-linux-gnu on x86_64 '\
        '(Source distribution)'
      ],
      centos7: [
        '5.5.40',
        'mysqld  Ver 5.5.40 for Linux on x86_64 (MySQL Community Server (GPL))'
      ],
      ubuntu10: [
        '5.1.73',
        'mysqld  Ver 5.1.73-0ubuntu0.10.04.1 for debian-linux-gnu on x86_64 '\
        '((Ubuntu))'
      ],
      ubuntu12: [
        '5.5.38',
        'mysqld  Ver 5.5.38-0ubuntu0.12.04.1-log for debian-linux-gnu on '\
        'x86_64 ((Ubuntu))'
      ],
      ubuntu14: [
        '5.5.38',
        'mysqld  Ver 5.5.38-0ubuntu0.14.04.1-log for debian-linux-gnu on '\
        'x86_64 ((Ubuntu))'
      ],
      debian6: [
        '5.1.73',
        'mysqld  Ver 5.1.73-1 for debian-linux-gnu on x86_64 ((Debian))'
      ],
      debian7: [
        '5.5.38',
        'mysqld  Ver 5.5.38-0+wheezy1-log for debian-linux-gnu on x86_64 '\
        '((Debian))'
      ],
      fedora19: [
        '5.5.38',
        '/usr/libexec/mysqld  Ver 5.5.38-log for Linux on x86_64 (MySQL '\
        'Community Server (GPL))'
      ],
      fedora20: [
        '5.5.38',
        '/usr/libexec/mysqld  Ver 5.5.38-log for Linux on x86_64 (MySQL '\
        'Community Server (GPL))'
      ],
      freebsd10: [
        '5.5.40',
        '/usr/local/libexec/mysqld  Ver 5.5.40-log for FreeBSD10.0 on amd64 '\
        '(Source distribution)'
      ]
    }.each do |platform, version_info|
      it "should parse #{platform} mysql versions" do
        version = version_info[0]
        stdout = version_info[1]
        expect(my_shell_out).to receive(:stdout).and_return(stdout)
        expect(subject.mysql_ver).to eql(version)
      end
    end # each platform version_info
  end # context #mysql_ver

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
        subject.non_interpolated_keys(%w(key1))
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
