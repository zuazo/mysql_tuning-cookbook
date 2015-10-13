#!/usr/bin/env ruby
# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Script:: plot_variables
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

require 'gnuplot'
require 'optparse'
require 'interpolator'
require 'chef/node'

def cookbook_attribute(name)
  "#{::File.dirname(__FILE__)}/../attributes/#{name}.rb"
end

def cookbook_library(name)
  "#{::File.dirname(__FILE__)}/../libraries/#{name}.rb"
end

require cookbook_library('mysql_interpolator')
require cookbook_library('mysql_helpers')
require cookbook_library('mysql_helpers_cnf')
require cookbook_library('cookbook_helpers')

# Parses arguments
class PlotVariablesOptionParser
  DEFAULT_ALGORITHMS = %w(proximal linear cubic catmull)
  # OpenOffice Colors:
  DEFAULT_COLORS = %w(
    #005796 #FF5317 #FFDA2E #69AB29 #8E002F #93D2FF
    #415108 #BAD700 #5D2D80 #FFA417 #CE0013 #0094D8
  )
  OPTIONS = [
    {
      short: '-p',
      long: '--png',
      description: 'Generates a PNG output',
      proc: proc { @options[:png] = true }
    },
    {
      short: '-a',
      long: '--algorithms ALGORITHMS',
      description: 'Algorithms separated by commas: '\
        'proximal, linear, cubic, bicubic, catmull',
      proc: proc { |v| @options[:algorithms] = v.split(/,\s*/) }
    }
  ]

  def initialize(args)
    @options = { algorithms: DEFAULT_ALGORITHMS, colors: DEFAULT_COLORS }
    parse_args(args)
  end

  def option_parser_add_options(optparse)
    OPTIONS.each do |option|
      optparse.on(option[:short], option[:long], option[:description]) do |v|
        instance_exec(v, &option[:proc])
      end
    end
  end

  def option_parser
    OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options] variable1 [variable2] [...]"
      option_parser_add_options(opts)
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end
  end

  def parse_args(args)
    optparse = option_parser
    optparse.parse!(args)
    @args = args
    return unless args.empty?
    puts optparse
    exit(-1)
  end

  def options
    @options.dup
  end

  def args
    @args.dup
  end
end

# Generates plots about MySQL variables interpolation
class PlotVariables
  POINTS_COUNT = 1000

  def initialize(args)
    parse_args(args)
  end

  def parse_args(args)
    parser = PlotVariablesOptionParser.new(args)
    @options = parser.options
    @variables = parser.args
  end

  def node
    @node ||= begin
      node = Chef::Node.new
      Dir.glob(cookbook_attribute('*')) do |f|
        node.from_file(f)
      end
      node
    end
  end

  def get_samples(variable)
    samples = node['mysql_tuning']['configuration_samples']
    samples.each_with_object({}) do |(mem, sample), r|
      next unless sample.key?('mysqld')
      next unless sample['mysqld'].key?(variable)
      r[mem] =
        MysqlTuningCookbook::MysqlHelpers.mysql2num(sample['mysqld'][variable])
    end
  end

  def mysql_round_variable(name, value)
    MysqlTuningCookbook::MysqlHelpers::Cnf.round_variable(
      name, value, node['mysql_tuning']['variables_block_size']
    )
  end

  def plot_data_set(title, xs, ys, color)
    Gnuplot::DataSet.new([xs, ys]) do |ds|
      ds.with = 'lines'
      ds.linewidth = 1.5
      ds.linecolor = "rgb \"#{color}\""
      ds.title = title
    end
  end

  def first_last_step(samples)
    first = samples.keys.first
    last = samples.keys.last * 2
    step = (last - first) / POINTS_COUNT
    [first, last, step]
  end

  def calculate_interpolated_values(variable, samples, algorithm)
    first, last, step = first_last_step(samples)
    interpolator = MysqlTuningCookbook::Interpolator.new(samples, algorithm)
    begin
      (first..last).step(step).each_with_object([[], []]) do |x, r|
        r[1] << mysql_round_variable(variable, interpolator.interpolate(x))
        r[0] << x
      end
    rescue RuntimeError
      [[], []]
    end
  end

  def plot_style_font(plot, font)
    plot.arbitrary_lines << "set xlabel font \"#{font}\""
    plot.arbitrary_lines << "set title font \"#{font}\""
    plot.arbitrary_lines << "set key font \"#{font}\""
    plot.arbitrary_lines << "set xtics font \"#{font}\""
    plot.arbitrary_lines << "set ytics font \"#{font}\""
  end

  def plot_style(plot)
    plot.arbitrary_lines << 'unset ylabel'
    plot_style_font(plot, 'Verdana 10')
    plot.arbitrary_lines << 'set key opaque'
    plot.arbitrary_lines << 'set format x "%.1s %cB"'
    plot.arbitrary_lines << 'set format y "%.1s %cB"'
    plot.arbitrary_lines << 'set grid lc rgb "#aaaaaa"'
  end

  def plot_init(plot, name)
    if @options[:png]
      plot.arbitrary_lines << 'set terminal pngcairo'
      plot.arbitrary_lines << "set output \"#{name}.png\""
    end
    plot.title name
    plot.xlabel 'System Memory'
    plot_style(plot)
  end

  def plot_variable(variable, colors)
    samples = get_samples(variable)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot_init(plot, variable)
        @options[:algorithms].each do |algorithm|
          xs, ys = calculate_interpolated_values(variable, samples, algorithm)
          plot.data << plot_data_set(algorithm, xs, ys, colors.shift)
        end
      end
    end
  end

  def plot_variables
    @variables.each do |v|
      plot_variable(v, @options[:colors].dup)
    end
  end
end

PlotVariables.new(ARGV).plot_variables
