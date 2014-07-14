# encoding: UTF-8

class MysqlTuning
  # Some MySQL Helpers to use from Chef cookbooks (recipes, attributes, ...)
  module CookbookHelpers
    KB = 1024
    MB = 1024 * KB
    GB = 1024 * MB
    IO_SIZE = 4 * KB

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

    # TODO: refactor this method, too complex
    def cnf_interpolation(cnf_samples, type, non_interpolated_keys)
      mysql_tuning_interpolator_install

      keys_by_ns = keys_to_interpolate(cnf_samples)

      keys_by_ns.each_with_object({}) do |(ns, keys), result|

        keys.each do |key|
          # Avoid interpolating some configuration values
          if (node['mysql_tuning']['non_interpolated_keys'][ns].is_a?(Array) &&
              node['mysql_tuning']['non_interpolated_keys'][ns].include?(key)) ||
             (non_interpolated_keys[ns].is_a?(Array) &&
              non_interpolated_keys[ns].include?(key))
            next
          end

          # get integer data points from samples
          previous_point = nil
          data_points = cnf_samples.each_with_object({}) do |(mem, cnf), r|
            r[mem] =
              if cnf.key?(ns) && MysqlTuning::MysqlHelpers.numeric?(cnf[ns][key])
                previous_point = MysqlTuning::MysqlHelpers.mysql2num(cnf[ns][key])
              # set to previous sample value if missing (value not changed)
              elsif !previous_point.nil?
                previous_point
              end
          end

          # interpolate data points
          interpolator = MysqlTuning::Interpolator.new(data_points, type)
          if interpolator.required_data_points <= data_points.count
            result[ns] = {} unless result.key?(ns)
            result[ns][key] = interpolator.interpolate(memory_for_mysql)
            Chef::Log.debug(
              "Interpolation(#{type}) of #{ns}.#{key}: "\
              "point = #{memory_for_mysql}, value = #{result[ns][key]}, "\
              "data_points = #{data_points.inspect}"
            )
          else
            Chef::Log.warn(
              "Cannot interpolate #{ns}.#{key}: not enough data points "\
              "(#{data_points.count} for #{interpolator.required_data_points}"
            )
          end

        end # keys.each
      end # keys_by_ns.reduce
    end

    # Lower-neighbor interpolation
    def cnf_proximal_interpolation(cnf_samples)
      cnf_samples.reduce({}) do |final_cnf, (mem, cnf)|
        if memory_for_mysql >= mem
          Chef::Mixin::DeepMerge.hash_only_merge(final_cnf, cnf)
        else
          final_cnf
        end
      end
    end

    def cnf_from_samples(cnf_samples, type, non_interpolated_keys)
      cnf_samples = Hash[cnf_samples.sort] # sort inc by RAM size

      result = cnf_proximal_interpolation(cnf_samples)
      unless [true, 'proximal'].include?(type)
        minimum_memory = cnf_samples.keys.sort[0] # first example
        if memory_for_mysql >= minimum_memory
          result_i = cnf_interpolation(cnf_samples, type, non_interpolated_keys)
          result = Chef::Mixin::DeepMerge.hash_only_merge(result, result_i)
        else
          Chef::Log.warn(
            'Memory for MySQL too low '\
            "(#{MysqlTuning::MysqlHelpers.num2mysql(memory_for_mysql)}), "\
            'non-proximal interpolation skipped'
          )
        end
      end
      mysql_round_cnf(result)
    end

    private

    # returns configuration keys that should be used for interpolation
    # TODO: refactor this method, too complex
    def keys_to_interpolate(cnf_samples)
      cnf_samples = cnf_samples.dup

      # remove keys setted in higher memory samples
      higher_memory_values = cnf_samples.keys.sort.select do |x|
        x > memory_for_mysql
      end
      # the first two higher values will be taken into account
      higher_memory_values.shift(2)
      cnf_samples.delete_if { |k, _v| higher_memory_values.include?(k) }

      # get setted config keys by namespace
      keys_by_ns = cnf_samples.each_with_object({}) do |(_memory, cnf), r|
        cnf.each do |ns, ns_cnf|
          r[ns] = ((r[ns] || []) + ns_cnf.keys).uniq
        end
      end

      # only select keys that have some values as numeric
      keys_by_ns.each_with_object({}) do |(ns, keys), r|
        r[ns] = keys.select do |key|
          # search this ns,key in cnf_samples and check if numeric
          cnf_samples.reduce(false) do |b, (_mem, cnf)|
            b ||
              if cnf.key?(ns)
                MysqlTuning::MysqlHelpers.numeric?(cnf[ns][key])
              else
                false
              end
          end # cnf_samples.reduce
        end # r[ns] = keys.select
      end # keys_by_ns.each_with_object
    end # #keys_to_interpolate
  end
end
