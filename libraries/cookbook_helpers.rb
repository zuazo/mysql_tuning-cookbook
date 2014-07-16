# encoding: UTF-8

class MysqlTuning
  # Some MySQL Helpers to use from Chef cookbooks (recipes, attributes, ...)
  module CookbookHelpers
    KB = 1024 unless defined?(KB)
    MB = 1024 * KB unless defined?(MB)
    GB = 1024 * MB unless defined?(GB)
    IO_SIZE = 4 * KB unless defined?(IO_SIZE)

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
      if node['mysql_tuning']['variables_block_size'].key?(name)
        base = node['mysql_tuning']['variables_block_size'][name]
        value = (MysqlTuning::MysqlHelpers.mysql2num(value) / base).round * base
      else
        value
      end
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
    def cnf_interpolation(cnf_samples, type, non_interpolated_keys)
      if samples_minimum_memory(cnf_samples) > memory_for_mysql
        Chef::Log.warn("Memory for MySQL too low (#{memory_for_mysql}), "\
          'non-proximal interpolation skipped')
        return {}
      end
      mysql_tuning_interpolator_install

      keys_by_ns = keys_to_interpolate(cnf_samples, non_interpolated_keys)
      keys_by_ns.each_with_object({}) do |(ns, keys), result|
        result[ns] = samples_interpolate_ns(cnf_samples, keys, ns, type)
      end
    end

    def cnf_proximal_interpolation(cnf_samples)
      cnf_samples = Hash[cnf_samples.sort] # sort inc by RAM size
      # TODO: proximal implementation inside Interpolator class should be used
      cnf_samples.reduce({}) do |final_cnf, (mem, cnf)|
        if memory_for_mysql >= mem
          Chef::Mixin::DeepMerge.hash_only_merge(final_cnf, cnf)
        else
          final_cnf
        end
      end
    end

    # generates interpolated cnf file from samples
    # proximal interpolation is used for non-interpolated values
    def cnf_from_samples(cnf_samples, type, non_interpolated_keys)
      result = cnf_proximal_interpolation(cnf_samples)
      if type != 'proximal'
        result_i = cnf_interpolation(cnf_samples, type, non_interpolated_keys)
        result = Chef::Mixin::DeepMerge.hash_only_merge(result, result_i)
      end
      mysql_round_cnf(result)
    end

    private

    # avoid interpolating some configuration values
    def non_interpolated_key?(ns, key, non_interpolated_keys = [])
      non_interpolated_keys[ns].is_a?(Array) &&
      non_interpolated_keys[ns].include?(key)
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

    def samples_interpolate_ns(cnf_samples, keys, ns, type)
      keys.each_with_object({}) do |key, r|
        Chef::Log.debug("Interpolating #{ns}.#{key}")
        data_points = samples_key_numeric_data_points(cnf_samples, ns, key)
        begin
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
    def keys_to_interpolate(cnf_samples, non_interpolated_keys = {})
      cnf_samples = samples_within_memory_range(cnf_samples)
      keys_by_ns = samples_setted_keys_by_ns(cnf_samples)

      # select keys that have some values as numeric and not excluded
      keys_by_ns.each_with_object({}) do |(ns, keys), r|
        r[ns] = keys.select do |key|
          !non_interpolated_key?(ns, key, non_interpolated_keys) &&
          samples_key_numeric?(cnf_samples, ns, key)
        end # r[ns] = keys.select
      end # keys_by_ns.each_with_object
    end # #keys_to_interpolate
  end
end
