# encoding: UTF-8
#
# Cookbook Name:: mysql_tuning
# Library:: cookbook_helpers
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

require 'mixlib/shellout'

class MysqlTuningCookbook
  # Some MySQL Helpers to use from Chef cookbooks (recipes, attributes, ...)
  module CookbookHelpers
    KB = 1024 unless defined?(KB)
    MB = 1024 * KB unless defined?(MB)
    GB = 1024 * MB unless defined?(GB)
    IO_SIZE = 4 * KB unless defined?(IO_SIZE)

    def mysql_cookbook_version
      run_context.cookbook_collection['mysql'].version
    end

    def mysql_cookbook_version_major
      mysql_cookbook_version.split('.', 2)[0].to_i
    end

    def install_required_gems(o)
      o.required_gems.each do |g|
        begin
          require g
        rescue LoadError
          r = chef_gem g
          r.action(:nothing)
          r.run_action(:install)
          require g
        end
      end
    end

    def mysql_ver
      mysql_bin = node['mysql_tuning']['mysqld_bin']
      @version ||= MysqlTuningCookbook::MysqlVersion.get(mysql_bin)
    end

    def physical_memory
      memory = node['memory']['total']
      return memory.to_i unless memory =~ /^([0-9]+)\s*([GMK])B$/i
      base = case Regexp.last_match[2].upcase
             when 'G' then 1_073_741_824
             when 'M' then 1_048_576
             when 'K' then 1024
             end
      Regexp.last_match[1].to_i * base
    end

    def memory_for_mysql
      @memory_for_mysql ||=
        (physical_memory * node['mysql_tuning']['system_percentage'] / 100)
        .round
    end

    # interpolates all the cnf_samples values
    def cnf_interpolation(cnf_samples, dtype, non_interp_keys, types = {})
      if samples_minimum_memory(cnf_samples) > memory_for_mysql
        Chef::Log.warn("Memory for MySQL too low (#{memory_for_mysql}), "\
          'non-proximal interpolation skipped')
        return {}
      end
      keys_by_group = keys_to_interpolate(cnf_samples, non_interp_keys)
      keys_by_group.each_with_object({}) do |(group, keys), result|
        result[group] =
          samples_interpolate_group(cnf_samples, group, keys, dtype, types)
      end
    end

    def cnf_proximal_interpolation(cnf_samples)
      # TODO: proximal implementation inside Interpolator class should be used
      cnf_samples = Hash[cnf_samples.sort] # sort inc by RAM size
      first_sample = cnf_samples.values.first
      cnf_samples.reduce(first_sample) do |final_cnf, (mem, cnf)|
        if memory_for_mysql >= mem
          Chef::Mixin::DeepMerge.hash_only_merge(final_cnf, cnf)
        else
          final_cnf
        end
      end
    end

    # generates interpolated cnf file from samples
    # proximal interpolation is used for non-interpolated values
    def cnf_from_samples(cnf_samples, dtype, non_interp_keys, types = {})
      result = cnf_proximal_interpolation(cnf_samples)
      if dtype != 'proximal' || !types.empty?
        result_i = cnf_interpolation(cnf_samples, dtype, non_interp_keys, types)
        result = Chef::Mixin::DeepMerge.hash_only_merge(result, result_i)
      end
      MysqlHelpers::Cnf.fix(
        result, node['mysql_tuning']['variables_block_size'],
        node['mysql_tuning']['old_names'], mysql_ver
      )
    end

    private

    # avoid interpolating some configuration values
    def non_interpolated_key?(key, non_interpolated_keys = [])
      non_interpolated_keys.is_a?(Array) &&
        non_interpolated_keys.include?(key)
    end

    # get integer data points from samples key
    def samples_key_numeric_data_points(cnf_samples, group, key)
      previous_point = nil
      cnf_samples.each_with_object({}) do |(mem, cnf), r|
        if cnf.key?(group) &&
           MysqlTuningCookbook::MysqlHelpers.numeric?(cnf[group][key])
          r[mem] = MysqlTuningCookbook::MysqlHelpers.mysql2num(cnf[group][key])
          previous_point = r[mem]
        # set to previous sample value if missing (value not changed)
        elsif !previous_point.nil?
          r[mem] = previous_point
        end
      end
    end

    # interpolate data points
    def interpolate_data_points(type, data_points, point)
      interpolator = MysqlTuningCookbook::Interpolator.new(data_points, type)
      install_required_gems(interpolator)
      required_points = interpolator.required_data_points
      if data_points.count < required_points
        raise "Not enough data points #{data_points.count} < #{required_points}"
      end
      result = interpolator.interpolate(point)
      Chef::Log.debug("Interpolation(#{type}): point = #{point}, "\
        "value = #{result}, data_points = #{data_points.inspect}")
      result
    end

    # remove samples for higher memory values
    def samples_within_memory_range(cnf_samples)
      higher_memory_values = cnf_samples.keys.sort.select do |x|
        x > memory_for_mysql
      end
      # the first two higher values will be taken into account
      higher_memory_values.shift(2)

      cnf_samples.select { |k, _v| !higher_memory_values.include?(k) }
    end

    # get setted config keys by group
    def samples_setted_keys_by_group(cnf_samples)
      cnf_samples.each_with_object({}) do |(_memory, cnf), r|
        cnf.each do |group, group_cnf|
          r[group] ||= []
          r[group] = (r[group] + group_cnf.keys).uniq
        end
      end
    end

    # search this group,key in cnf_samples and check if numeric
    def samples_key_numeric?(cnf_samples, group, key)
      cnf_samples.reduce(false) do |r, (_mem, cnf)|
        next true if r
        if cnf.key?(group)
          MysqlTuningCookbook::MysqlHelpers.numeric?(cnf[group][key])
        else
          false
        end
      end # cnf_samples.reduce
    end

    def determine_interpolation_type(key, default_type, types)
      return default_type unless types.key?(key)
      types[key]
    end

    def samples_interpolate_group(cnf_samples, group, keys, default_type, types)
      keys.each_with_object({}) do |key, r|
        Chef::Log.debug("Interpolating #{group}.#{key}")
        data_points = samples_key_numeric_data_points(cnf_samples, group, key)
        begin
          type = determine_interpolation_type(key, default_type, types)
          r[key] = interpolate_data_points(type, data_points, memory_for_mysql)
        rescue RuntimeError => e
          Chef::Log.warn("Cannot interpolate #{group}.#{key}: #{e.message}")
        end
      end
    end

    def samples_minimum_memory(cnf_samples)
      cnf_samples.keys.sort[0]
    end

    # returns configuration keys that should be used for interpolation
    def keys_to_interpolate(cnf_samples, non_interp_keys = {})
      cnf_samples = samples_within_memory_range(cnf_samples)
      keys_by_group = samples_setted_keys_by_group(cnf_samples)

      # select keys that have some values as numeric and not excluded
      keys_by_group.each_with_object({}) do |(group, keys), r|
        r[group] = keys.select do |key|
          !non_interpolated_key?(key, non_interp_keys) &&
            samples_key_numeric?(cnf_samples, group, key)
        end # r[group] = keys.select
      end # keys_by_group.each_with_object
    end # #keys_to_interpolate
  end
end
