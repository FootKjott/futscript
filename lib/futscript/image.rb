module Futscript
  class Image
    attr_accessor :width, :height, :size

    def initialize bmi, bitmap_data
      @width = bmi[1]
      @height = bmi[2]
      @size = bmi[6]
      @data = bitmap_data
    end

    def get_pixel x, y
      y = @height - y - 1
      raise "Invalid coordinates" unless (0...@width).include?(x) && (0...@height).include?(y)
      colorref = @data[(y * @width + x) * 3, 3].unpack('CCC')
      return Color.new(colorref[2], colorref[1], colorref[0])
    end

    def scan color, tolerance=0
      color = Color.parse color
      (0...@width).each do |x|
        (0...@height).each do |y|
          return [x, y] if color.is_tolerant_of(get_pixel(x, y), tolerance)
        end
      end
    end

    def destroy
      @width = 0
      @height = 0
      @size = 0
      @data = nil
    end
  end
end