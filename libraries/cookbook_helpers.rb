# encoding: UTF-8

require 'chef/mixin/command'

class MysqlTuning
  # Some MySQL Helpers to use from Chef cookbooks (recipes, attributes, ...)
  module CookbookHelpers
    include Chef::Mixin::Command

    KB = 1024 unless defined?(KB)
    MB = 1024 * KB unless defined?(MB)
    GB = 1024 * MB unless defined?(GB)
    IO_SIZE = 4 * KB unless defined?(IO_SIZE)

    def mysql_version
      @mysql_version ||= begin
        _status, stdout, _stderr = run_command_and_return_stdout_stderr(
          no_status_check: true,
          command: "#{node['mysql_tuning']['mysqld_bin']} --version")
        if stdout.split("\n")[0] =~ / +Ver +([0-9][0-9.]*)[^0-9.]/
          Regexp.last_match[1]
        end
      rescue
        nil
      end
    end

    def mysql_version_satisfies?(requirement)
      return false if mysql_version.nil?
      version = Gem::Version.new(mysql_version)
      Gem::Requirement.new(requirement).satisfied_by?(version)
    end

    def mysql_fix_key(name)
      return name unless node['mysql_tuning']['old_names'].key?(name)
      result = name
      node['mysql_tuning']['old_names'][name].each do |requirement, old_name|
        next unless mysql_version_satisfies?(requirement)
        Chef::Log.info("Fixing configuration key #{name} by #{old_name}")
        result = old_name
      end
      result
    end

    def mysql_fix_cnf(cnf)
      cnf.each_with_object({}) do |(ns, values), r|
        r[ns] = {}
        values.each do |key, value|
          fixed_key = mysql_fix_key(key)
          r[ns][fixed_key] = value unless fixed_key.nil?
        end
      end
    end

    def mysql_tuning_interpolator_install
      return unless node['mysql_tuning']['interpolation'] == true ||
         node['mysql_tuning']['interpolation'].is_a?(String)

      MysqlTuning::Interpolator.required_gems.each do |g|
        r = chef_gem g do
          action :nothing
        end
        r.run_action(:install)
        require g
      end
    end

    def mysql_round_variable(name, value)
      MysqlTuning::MysqlHelpers.mysql_round_variable(
        name,
        value,
        node['mysql_tuning']['variables_block_size']
      )
    end

    def mysql_round_cnf(cnf)
      cnf.each_with_object({}) do |(ns, keys), r|
        r[ns] = {}
        keys.each do |key, value|
          r[ns][key] = mysql_round_variable(key, value)
        end
      end
    end

    def physical_memory
      @physical_memory ||=
        case node['memory']['total']
        when /^([0-9]+)\s*GB$/i then Regexp.last_match[1].to_i * 1_073_741_824
        when /^([0-9]+)\s*MB$/i then Regexp.last_match[1].to_i * 1_048_576
        when /^([0-9]+)\s*KB$/i then Regexp.last_match[1].to_i * 1024
        else
          node['memory']['total'].to_i
        end
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
      mysql_tuning_interpolator_install
      keys_by_ns = keys_to_interpolate(cnf_samples, non_interp_keys)
      keys_by_ns.each_with_object({}) do |(ns, keys), result|
        result[ns] = samples_interpolate_ns(cnf_samples, ns, keys, dtype, types)
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
      mysql_round_cnf(mysql_fix_cnf(result))
    end

    private

    # avoid interpolating some configuration values
    def non_interpolated_key?(ns, key, non_interp_keys = [])
      non_interp_keys[ns].is_a?(Array) &&
      non_interp_keys[ns].include?(key)
    end

    # get integer data points from samples key
    def samples_key_numeric_data_points(cnf_samples, ns, key)
      previous_point = nil
      cnf_samples.each_with_object({}) do |(mem, cnf), r|
        if cnf.key?(ns) && MysqlTuning::MysqlHelpers.numeric?(cnf[ns][key])
          r[mem] = MysqlTuning::MysqlHelpers.mysql2num(cnf[ns][key])
          previous_point = r[mem]
        # set to previous sample value if missing (value not changed)
        elsif !previous_point.nil?
          r[mem] = previous_point
        end
      end
    end

    # interpolate data points
    def interpolate_data_points(type, data_points, point)
      interpolator = MysqlTuning::Interpolator.new(data_points, type)
      required_points = interpolator.required_data_points
      points_count = data_points.count
      if required_points > points_count
        fail "Not enough data points (#{points_count} for #{required_points})"
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

    # get setted config keys by namespace
    def samples_setted_keys_by_ns(cnf_samples)
      cnf_samples.each_with_object({}) do |(_memory, cnf), r|
        cnf.each do |ns, ns_cnf|
          r[ns] ||= []
          r[ns] = (r[ns] + ns_cnf.keys).uniq
        end
      end
    end

    # search this ns,key in cnf_samples and check if numeric
    def samples_key_numeric?(cnf_samples, ns, key)
      cnf_samples.reduce(false) do |r, (_mem, cnf)|
        next true if r
        if cnf.key?(ns)
          MysqlTuning::MysqlHelpers.numeric?(cnf[ns][key])
        else
          false
        end
      end # cnf_samples.reduce
    end

    def determine_interpolation_type(ns, key, default_type, types)
      return default_type unless types.key?(ns) && types[ns].key?(key)
      types[ns][key]
    end

    def samples_interpolate_ns(cnf_samples, ns, keys, default_type, types)
      keys.each_with_object({}) do |key, r|
        Chef::Log.debug("Interpolating #{ns}.#{key}")
        data_points = samples_key_numeric_data_points(cnf_samples, ns, key)
        begin
          type = determine_interpolation_type(ns, key, default_type, types)
          r[key] = interpolate_data_points(type, data_points, memory_for_mysql)
        rescue RuntimeError => e
          Chef::Log.warn("Cannot interpolate #{ns}.#{key}: #{e.message}")
        end
      end
    end

    def samples_minimum_memory(cnf_samples)
      cnf_samples.keys.sort[0]
    end

    # returns configuration keys that should be used for interpolation
    def keys_to_interpolate(cnf_samples, non_interp_keys = {})
      cnf_samples = samples_within_memory_range(cnf_samples)
      keys_by_ns = samples_setted_keys_by_ns(cnf_samples)

      # select keys that have some values as numeric and not excluded
      keys_by_ns.each_with_object({}) do |(ns, keys), r|
        r[ns] = keys.select do |key|
          !non_interpolated_key?(ns, key, non_interp_keys) &&
          samples_key_numeric?(cnf_samples, ns, key)
        end # r[ns] = keys.select
      end # keys_by_ns.each_with_object
    end # #keys_to_interpolate
  end
end
