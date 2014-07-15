# encoding: UTF-8

class MysqlTuning
  # This class contains the interpolation logic.
  # Does interpolation based on some data points and interpolation type.
  class Interpolator
    def self.required_gems
      %w(interpolator)
    end

    def initialize(data_points, type)
      data_points(data_points)
      type(type)
    end

    # convert all values to float and sort them
    def data_points(data_points)
      points = data_points.each_with_object({}) do |(k, v), r|
        r[k.to_f] = v.to_f
      end
      @data_points = Hash[points.sort]
    end

    def type(type)
      @type =
      case type.downcase
      when 'linear' then ::Interpolator::Table::LINEAR
      when 'cubic' then ::Interpolator::Table::CUBIC
      when 'bicubic', 'lagrange'
        @data_points.count > 3 ? ::Interpolator::Table::LAGRANGE3 : ::Interpolator::Table::LAGRANGE2
      when 'catmull' then ::Interpolator::Table::CATMULL
      else
        @type
      end
    end

    def required_data_points
      case @type
      when ::Interpolator::Table::LINEAR, ::Interpolator::Table::CATMULL
        2
      when ::Interpolator::Table::CUBIC, ::Interpolator::Table::LAGRANGE2
        3
      when ::Interpolator::Table::LAGRANGE3 then 4
      when 'proximal' then 1
      else
        fail "Unknown required data points for #{@type.inspect} interpolation"
      end
    end

    # Lower-neighbor interpolation
    def proximal_interpolation(value)
      first_value = @data_points.values.first
      @data_points.reduce(first_value) do |r, (x, y)|
        x < value ? y : r
      end
    end

    def interpolate(value)
      case @type
      when 'proximal'
        proximal_interpolation(value)
      else
        t = ::Interpolator::Table.new(@data_points)
        t.style = @type
        t.interpolate(value).round
      end
    end
  end
end
