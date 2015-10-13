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
require 'mysql_interpolator'
require 'interpolator'

describe MysqlTuningCookbook::Interpolator do
  subject { described_class.new({}, 'linear') }

  context '#new' do
    before do
      allow_any_instance_of(described_class).to receive(:data_points)
      allow_any_instance_of(described_class).to receive(:type)
    end

    it 'should set data_points' do
      expect_any_instance_of(described_class)
        .to receive(:data_points).with('data_points')
      described_class.new('data_points', 'type')
    end

    it 'should set type' do
      expect_any_instance_of(described_class)
        .to receive(:type).with('type')
      described_class.new('data_points', 'type')
    end
  end # context #new

  context '#data_points' do
    it 'should convert all values to floats' do
      subject.data_points(
        '1' => '2',
        '3.0' => '4.0',
        5 => 6,
        7.0 => 8.0
      )
      expect(subject.data_points).to eql(
        1.0 => 2.0,
        3.0 => 4.0,
        5.0 => 6.0,
        7.0 => 8.0
      )
    end
  end # context #data_points

  context '#type_raw' do
    {
      'linear' => ::Interpolator::Table::LINEAR,
      'cubic' => ::Interpolator::Table::CUBIC,
      'bicubic' => ::Interpolator::Table::LAGRANGE2,
      'catmull' => ::Interpolator::Table::CATMULL,
      'proximal' => 'proximal',
      'randomtype' => 'randomtype'
    }.each do |type, value|
      it "should set #{type} type to #{value} internally" do
        subject.type(type)
        expect(subject.type_raw).to eql(value)
      end
    end # each do |type, value|
  end # context #type

  context '#required_data_points' do
    {
      'proximal' => 1,
      'linear' => 2,
      'catmull' => 2,
      'cubic' => 3,
      'bicubic' => 3,
      'lagrange' => 3,
      ::Interpolator::Table::LINEAR => 2,
      ::Interpolator::Table::CATMULL => 2,
      ::Interpolator::Table::CUBIC => 3,
      ::Interpolator::Table::LAGRANGE2 => 3,
      ::Interpolator::Table::LAGRANGE3 => 4
    }.each do |type, points|
      it "should require #{points} points for #{type}" do
        subject.type(type)
        expect(subject.required_data_points).to eql(points)
      end
    end # each do |type, points|

    it 'should raise an error for unknown types' do
      subject.type('bad_type')
      expect { subject.required_data_points }
        .to raise_error(RuntimeError, /Unknown required data points/)
    end
  end # context #required_data_points

  context '#interpolate' do
    before do
      subject.data_points(
        10 => 20,
        20 => 30,
        30 => 40,
        50 => 45
      )
    end

    context 'proximal type' do
      before do
        subject.type('proximal')
      end

      it 'should interpolate equal values correctly' do
        expect(subject.interpolate(20)).to eql(30)
      end

      it 'should interpolate low values correctly' do
        expect(subject.interpolate(5)).to eql(20)
      end

      it 'should interpolate higher values correctly' do
        expect(subject.interpolate(35)).to eql(40)
      end
    end # context proximal type

    context 'linear type' do
      before do
        subject.type('linear')
      end

      it 'should interpolate equal values correctly' do
        expect(subject.interpolate(20)).to eql(30)
      end

      it 'should interpolate low values correctly' do
        expect(subject.interpolate(5)).to eql(15)
      end

      it 'should interpolate intermediate values correctly' do
        expect(subject.interpolate(15)).to eql(25)
        expect(subject.interpolate(35)).to eql(41)
      end

      it 'should interpolate high values correctly' do
        expect(subject.interpolate(60)).to eql(48)
      end
    end # context linear type

    context 'cubic type' do
      before do
        subject.type('cubic')
      end

      it 'should interpolate equal values correctly' do
        expect(subject.interpolate(20)).to eql(30)
      end

      it 'should interpolate low values correctly' do
        expect(subject.interpolate(5)).to eql(15)
      end

      it 'should interpolate intermediate values correctly' do
        expect(subject.interpolate(15)).to eql(25)
        expect(subject.interpolate(35)).to eql(43)
      end

      it 'should interpolate high values correctly' do
        expect(subject.interpolate(60)).to eql(46)
      end
    end # context cubic type

    context 'bicubic type' do
      before do
        subject.type('bicubic')
      end

      it 'should interpolate equal values correctly' do
        expect(subject.interpolate(20)).to eql(30)
      end

      it 'should interpolate low values correctly' do
        expect(subject.interpolate(5)).to eql(16)
      end

      it 'should interpolate intermediate values correctly' do
        expect(subject.interpolate(15)).to eql(25)
        expect(subject.interpolate(35)).to eql(44)
      end

      it 'should interpolate high values correctly (?)' do
        expect(subject.interpolate(60)).to eql(33)
      end
    end # context bicubic type

    context 'catmull type' do
      before do
        subject.type('catmull')
      end

      it 'should interpolate equal values correctly' do
        expect(subject.interpolate(20)).to eql(30)
      end

      it 'should interpolate low values correctly' do
        expect(subject.interpolate(5)).to eql(15)
      end

      it 'should interpolate intermediate values correctly' do
        expect(subject.interpolate(15)).to eql(25)
        expect(subject.interpolate(35)).to eql(42)
      end

      it 'should interpolate high values correctly' do
        expect(subject.interpolate(60)).to eql(49)
      end
    end # context catmull type

    it 'should raise an error for unknown types' do
      subject.type('bad_type')
      expect { subject.interpolate(10) }
        .to raise_error(RuntimeError, /invalid interpolation type/)
    end
  end # context #interpolate
end
