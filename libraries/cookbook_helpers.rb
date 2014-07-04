
class MysqlTuning

  module CookbookHelpers
    KB = 1024
    MB = 1024 * KB
    GB = 1024 * MB

    def mysql_tuning_interpolator_install
      if node['mysql_tuning']['interpolation'] === true or
         node['mysql_tuning']['interpolation'].kind_of?(String)
        MysqlTuning::Interpolator.required_gems.each do |g|
          r = chef_gem g do
            action :nothing
          end
          r.run_action(:install)
          require g
        end
      end
    end

    def physical_memory
      @physical_memory ||=
        case node['memory']['total']
        when /^([0-9]+)\s*GB$/i
          $1.to_i * 1073741824
        when /^([0-9]+)\s*MB$/i
          $1.to_i * 1048576
        when /^([0-9]+)\s*KB$/i
          $1.to_i * 1024
        else
          node['memory']['total'].to_i
        end
    end

    def memory_for_mysql
      @memory_for_mysql ||= (physical_memory * node['mysql_tuning']['system_percentage'] / 100).round
    end

    # TODO refactor this method, too complex
    def cnf_interpolation(cnf_samples, type, non_interpolated_keys)
      mysql_tuning_interpolator_install

      keys_by_ns = keys_to_interpolate(cnf_samples)

      keys_by_ns.reduce({}) do |result, (ns, keys)|

        keys.each do |key|
          # Avoid interpolating some configuration values
          if ( node['mysql_tuning']['non_interpolated_keys'][ns].kind_of?(Array) and
               node['mysql_tuning']['non_interpolated_keys'][ns].include?(key) ) or
             ( non_interpolated_keys[ns].kind_of?(Array) and
               non_interpolated_keys[ns].include?(key) )
            next
          end

          # get integer data points from samples
          previous_point = nil
          data_points = cnf_samples.reduce({}) do |r, (mem, cnf)|
            if cnf.has_key?(ns) and MysqlTuning::MysqlHelpers.is_numeric?(cnf[ns][key])
               r[mem] = previous_point = MysqlTuning::MysqlHelpers.mysql2num(cnf[ns][key])
            # set to previous sample value if missing (value not changed)
            elsif ! previous_point.nil?
              r[mem] = previous_point
            end
            r
          end

          # interpolate data points
          interpolator = MysqlTuning::Interpolator.new(data_points, type)
          if interpolator.required_data_points <= data_points.count
            result[ns] = {} unless result.has_key?(ns)
            result[ns][key] = interpolator.interpolate(memory_for_mysql)
            Chef::Log.debug("Interpolation(#{type}) of #{ns}.#{key}: point = #{memory_for_mysql}, value = #{result[ns][key]}, data_points = #{data_points.inspect}")
          else
            Chef::Log.warn("Cannot interpolate #{ns}.#{key}: not enough data points (#{data_points.count} for #{interpolator.required_data_points}")
          end

        end # keys.each
        result
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
      unless [ true, 'proximal' ].include?(type)
        minimum_memory = cnf_samples.keys.sort[0] # first example
        if memory_for_mysql >= minimum_memory
          result_i = cnf_interpolation(cnf_samples, type, non_interpolated_keys)
          Chef::Mixin::DeepMerge.hash_only_merge(result, result_i)
        else
          Chef::Log.warn("Memory for MySQL too low (#{MysqlTuning::MysqlHelpers.num2mysql(memory_for_mysql)}), non-proximal interpolation skipped")
        end
      else
        result
      end
    end

    private

    # returns configuration keys that should be used for interpolation
    # TODO refactor this method, too complex
    def keys_to_interpolate(cnf_samples)
      cnf_samples = cnf_samples.dup

      # remove keys setted in higher memory samples
      higher_memory_values = cnf_samples.keys.sort.select { |x| x > memory_for_mysql }
      higher_memory_values.shift(2) # the first two higher values will be taken into account
      cnf_samples.delete_if { |k, v| higher_memory_values.include?(k) }

      # get setted config keys by namespace
      keys_by_ns = cnf_samples.reduce({}) do |r, (memory, cnf)|
        cnf.each do |ns, ns_cnf|
          r[ns] = ( ( r[ns] || [] ) + ns_cnf.keys ).uniq
        end
        r
      end

      # only select keys that have some values as numeric
      keys_by_ns.reduce({}) do |r, (ns, keys)|
        r[ns] = keys.select do |key|
          # search this ns,key in cnf_samples and check if numeric
          cnf_samples.reduce(false) do |r, (mem, cnf)|
            r || ( cnf.has_key?(ns) ? MysqlTuning::MysqlHelpers.is_numeric?(cnf[ns][key]) : false )
          end
        end
        r
      end
    end

  end

end
