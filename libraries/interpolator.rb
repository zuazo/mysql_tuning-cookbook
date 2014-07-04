
class MysqlTuning

  class Interpolator

    def self.required_gems
      %w{interpolator}
    end

    def initialize(data_points, type)
      data_points(data_points)
      type(type)
    end

    # convert all values to float
    def data_points(data_points)
      @data_points = data_points.reduce({}) do |r, (k, v)|
        r[k.to_f] = v.to_f
        r
      end
    end

    def type(type)
      @type = case type.downcase
      when 'linear'
        ::Interpolator::Table::LINEAR
      when 'cubic'
        ::Interpolator::Table::CUBIC
      when 'bicubic', 'lagrange'
        @data_points.count > 3 ? ::Interpolator::Table::LAGRANGE3 : ::Interpolator::Table::LAGRANGE2
      when 'catmull'
        ::Interpolator::Table::CATMULL
      else
        raise "Unknown interpolation type: #{type}"
      end
    end

    def required_data_points
      case @type
      when ::Interpolator::Table::LINEAR, ::Interpolator::Table::CATMULL
        2
      when ::Interpolator::Table::CUBIC, ::Interpolator::Table::LAGRANGE2
        3
      when ::Interpolator::Table::LAGRANGE3
        4
      else
        raise "Unknown interpolation required data points for: #{@type.inspect}"
      end
    end

    def interpolate(value)
      t = ::Interpolator::Table.new(@data_points)
      t.style = @type
      t.interpolate(value).round
    end

  end

end
