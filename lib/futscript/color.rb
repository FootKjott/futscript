module Futscript
  class Color
    attr_accessor :r, :g, :b
    def initialize r=0, g=0, b=0
      @r = r 
      @g = g
      @b = b
    end

    def is_tolerant_of color, tolerance=5
      return ((@r-color.r).abs <= tolerance &&
              (@g-color.g).abs <= tolerance &&
              (@b-color.b).abs <= tolerance)
    end

    def self.from_hex str
      return Color.new(str[0,2].to_i(16), str[2,2].to_i(16), str[4,2].to_i(16))
    end
  end
end