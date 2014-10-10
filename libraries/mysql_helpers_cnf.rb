# encoding: UTF-8

class MysqlTuning
  class MysqlHelpers
    # Some generic helpers related with configuration files
    class Cnf
      def self.fix_variable(name, old_names)
        return name unless old_names.key?(name)
        result = name
        old_names[name].each do |requirement, old_name|
          next unless MysqlHelpers.version_satisfies?(requirement)
          Chef::Log.info("Fixing MySQL variable #{name} by #{old_name}")
          result = old_name
        end
        result
      end

      def self.round_variable(name, value, variables_block_size)
        if variables_block_size.key?(name)
          base = variables_block_size[name]
          (MysqlHelpers.mysql2num(value) / base).round * base
        else
          value
        end
      end

      def self.fix(cnf, block_sizes = {}, old_names = {})
        cnf.each_with_object({}) do |(group, values), r|
          r[group] = {}
          values.each do |key, value|
            fixed_key = fix_variable(key, old_names)
            unless fixed_key.nil?
              fixed_value = round_variable(key, value, block_sizes)
              r[group][fixed_key] = fixed_value
            end
          end
        end
      end
    end
  end
end
