
module MysqlTuning

  module AttributeHelpers
    KB = 1024
    MB = 1024 * KB
    GB = 1024 * MB

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

    def cnf_from_samples(cnf_samples)
      cnf_samples = Hash[cnf_samples.sort] # sort inc by RAM size

      cnf_samples.reduce({}) do |final_cnf, (required_ram, cnf)|
        if physical_memory >= required_ram
          Chef::Mixin::DeepMerge.hash_only_merge(final_cnf, cnf)
        else
          final_cnf
        end
      end
    end

  end

end
