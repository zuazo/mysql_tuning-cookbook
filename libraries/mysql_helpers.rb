# encoding: UTF-8

class MysqlTuning
  # Some generic helpers related with MySQL
  class MysqlHelpers
    def self.numeric?(num)
      case num
      when Numeric
        true
      when /^[0-9]+[GMKB]?$/
        true
      else
        false
      end
    end

    def self.mysql2num(num)
      if num =~ /^([0-9]+)([GMKB])$/
        case Regexp.last_match[2]
        when 'G' then Regexp.last_match[1].to_i * 1_073_741_824
        when 'M' then Regexp.last_match[1].to_i * 1_048_576
        when 'K' then Regexp.last_match[1].to_i * 1024
        when 'B' then Regexp.last_match[1].to_i
        end
      else
        num.to_i
      end
    end

    def self.num2mysql(num)
      if num > 10_737_418_240
        "#{(num / 1_073_741_824).floor}G"
      elsif num > 10_485_760
        "#{(num / 1_048_576).floor}M"
      elsif num > 10_240
        "#{(num / 1024).floor}K"
      else
        num.to_s
      end
    end

    def self.mysql_round_variable(name, value, variables_block_size)
      if variables_block_size.key?(name)
        base = variables_block_size[name]
        value = (MysqlTuning::MysqlHelpers.mysql2num(value) / base).round * base
      else
        value
      end
    end

    # Returns true if all variables has been set correctly
    def self.set_variables(vars, user, password, port)
      db = connect(user, password, port.to_i)

      result = vars.reduce(true) do |r, (key, value)|
        return false unless r
        set_variable(db, key, value)
      end

      disconnect(db)
      result
    end

    # private

    def self.connect(user, password, port)
      require 'mysql'
      # TODO: use the socket?
      db = ::Mysql.new('localhost', user, password, nil, port)
      db.set_server_option(::Mysql::OPTION_MULTI_STATEMENTS_ON)
      db
    end
    private_class_method :connect

    def self.disconnect(db)
      db.close rescue nil
    end
    private_class_method :disconnect

    def self.variable_exists?(db, name)
      value = db.query("SHOW GLOBAL VARIABLES LIKE '#{db.escape_string(name)}'")
      value.num_rows > 0
    end
    private_class_method :variable_exists?

    def self.get_variable(db, name)
      value = db.query("SHOW GLOBAL VARIABLES LIKE '#{db.escape_string(name)}'")
      if value.num_rows > 0
        value.fetch_row[1]
      else
        nil
      end
    end
    private_class_method :get_variable

    def self.set_variable_query(db, name, value)
      stmt.execute(db.prepare("SET GLOBAL #{name} = ?"))
      Chef::Log.info("Changed MySQL #{key.inspect} variable "\
        "from #{orig.inspect} to #{value.inspect} dynamically")
      true
    rescue
      Chef::Log.info("MySQL #{key.inspect} variable cannot be changed "\
        "from #{orig.inspect} to #{value.inspect} dynamically.")
      false
    end
    private_class_method :set_variable_query

    def self.set_variable(db, name, value)
      return false unless variable_exists?(db, name)
      return true if get_variable(db, name).to_s == value.to_s
      set_variable_query(db, name, value)
    end
    private_class_method :set_variable
  end
end
