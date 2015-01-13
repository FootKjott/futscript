module Futscript
  class Color
    attr_accessor :r, :g, :b
    def initialize r=0, g=0, b=0
      @r = r 
      @g = g
      @b = b
    end

    def is_tolerant_of color, tolerance=5
      return ((@r - color.r).abs <= tolerance &&
              (@g - color.g).abs <= tolerance &&
              (@b - color.b).abs <= tolerance)
    end

    def self.parse c
      case c
      when Integer
        Color.new((c / 65536) % 256, (c / 256) % 256, c % 256)
      when String
        Color.new(c[0,2].to_i(16), c[2,2].to_i(16), c[4,2].to_i(16))
      when Hash
        Color.new(c[:r], c[:g], c[:b])
      when Color
        c
      else
        raise "Invalid hex color data type"
      end
    end

    def self.from_hex hex
      parse hex
    end
  end
end