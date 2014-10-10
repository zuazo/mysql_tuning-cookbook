# encoding: UTF-8

class MysqlTuning
  # This class contains the interpolation logic.
  # Does interpolation based on some data points and interpolation type.
  class Interpolator
    def initialize(data_points, type)
      data_points(data_points)
      type(type)
    end

    def required_gems
      depends = []
      depends << 'interpolator' if @type != 'proximal'
      depends
    end

    # convert all values to float and sort them
    def data_points(data_points = nil)
      if data_points.nil?
        @data_points
      else
        @data_points = data_points_filter(data_points)
      end
    end

    def type(type = nil)
      if type.nil?
        @type
      else
        @type = type
      end
    end

    def required_data_points
      case type_raw
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

    def interpolate(value)
      case @type
      when 'proximal'
        proximal_interpolation(value)
      else
        t = ::Interpolator::Table.new(@data_points)
        t.style = type_raw
        t.interpolate(value).round
      end
    end

    def bicubic_type_raw
      if @data_points.count > 3
        ::Interpolator::Table::LAGRANGE3
      else
        ::Interpolator::Table::LAGRANGE2
      end
    end

    def type_raw
      case @type.to_s
      when 'linear' then ::Interpolator::Table::LINEAR
      when 'cubic' then ::Interpolator::Table::CUBIC
      when 'bicubic', 'lagrange' then bicubic_type_raw
      when 'catmull' then ::Interpolator::Table::CATMULL
      else
        @type
      end
    end

    private

    def data_points_filter(data_points)
      points = data_points.each_with_object({}) do |(k, v), r|
        r[k.to_f] = v.to_f
      end
      Hash[points.sort]
    end

    # Lower-neighbor interpolation
    def proximal_interpolation(value)
      first_value = @data_points.values.first
      @data_points.reduce(first_value) do |r, (x, y)|
        x <= value ? y : r
      end.round
    end
  end
end
