
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

  end

end
