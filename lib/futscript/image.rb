module Futscript
  class Image
    attr_accessor :width, :height, :size

    def initialize width, height, size, data
      @height = height
      @width = width
      @size = size
      @data = data
    end

    def self.from_bmi_data bmi, bitmap_data
      Image.new(bmi[1], bmi[2], bmi[6], bitmap_data)
    end

    def pixel x, y=nil
      if y.nil?
        y = x[1]
        x = x[0]
      end
      y = @height - y - 1
      raise "Invalid coordinates" unless (0...@width).include?(x) && (0...@height).include?(y)
      colorref = @data[(y * @width + x) * 3, 3].unpack('CCC')
      return Color.new(colorref[2], colorref[1], colorref[0])
    end

    def scan color, tolerance=0
      color = Color.parse color
      (0...@width).each do |x|
        (0...@height).each do |y|
          return [x, y] if color.tolerant_of?(pixel(x, y), tolerance)
        end
      end
      nil
    end

    def count color, tolerance=0
      count = 0
      color = Color.parse color
      (0...@width).each do |x|
        (0...@height).each do |y|
          count += 1 if color.tolerant_of?(pixel(x, y), tolerance)
        end
      end
      count
    end
  end
end