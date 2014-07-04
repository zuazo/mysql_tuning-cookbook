
class MysqlTuning

  class MysqlHelpers

    def self.is_numeric?(num)
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
      case num
      when Numeric
        num
      when /^([0-9]+)([GMKB]?)$/
        case $2
        when 'G'
          $1.to_i * 1073741824
        when 'M'
          $1.to_i * 1048576
        when 'K'
          $1.to_i * 1024
        else
          $1.to_i
        end
      end
    end

    def self.num2mysql(num)
      if num > 10737418240
        "#{(num / 1073741824).floor}G"
      elsif num > 10485760
        "#{(num / 1048576).floor}M"
      elsif num > 10240
        "#{(num / 1024).floor}K"
      else
        num.to_s
      end
    end

    # Returns true if all variables has been correctly set
    def self.set_variables(vars, user, password, port)
      db = self.connect(user, password, port.to_i)

      result = vars.reduce(true) do |r, (key, value)|
        r && if self.variable_exists?(db, key)
          orig = self.get_variable(db, key)
          if orig.to_s != value.to_s
            changed = self.set_variable(db, key, value)
            if changed
              Chef::Log.info("Changed MySQL #{key.inspect} variable from #{orig.inspect} to #{value.inspect} dynamically")
            else
              Chef::Log.info("MySQL #{key.inspect} variable cannot be changed from #{orig.inspect} to #{value.inspect} dynamically.")
            end
            changed
          else
            true
          end
        else
          false
        end
      end

      self.disconnect(db)
      result
    end

    private

    def self.connect(user, password, port)
      require 'mysql'
      # TODO use the socket?
      db = ::Mysql.new('localhost', user, password, nil, port)
      db.set_server_option(::Mysql::OPTION_MULTI_STATEMENTS_ON)
      db
    end

    def self.disconnect(db)
      db.close rescue nil
    end

    def self.variable_exists?(db, name)
      value = db.query("SHOW GLOBAL VARIABLES LIKE '#{db.escape_string(name)}'")
      value.num_rows > 0
    end

    def self.get_variable(db, name)
      value = db.query("SHOW GLOBAL VARIABLES LIKE '#{db.escape_string(name)}'")
      if value.num_rows > 0
        value.fetch_row[1]
      else
        nil
      end
    end

    def self.set_variable(db, name, value)
      # The variable name has been checked in #variable_exists?
      stmt = db.prepare("SET GLOBAL #{name} = ?");
      begin
        stmt.execute(value)
        true
      rescue
        false
      end
    end

  end
end
