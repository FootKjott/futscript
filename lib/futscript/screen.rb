require 'futscript/screen_ext/screen_ext'

module Futscript
  class Screen
    @@defaults = { tolerance: 5, timeout: 10000, period: 50 }

    def self.defaults
      @@defaults
    end

    def self.offset_x
      @@offset_x
    end

    def self.offset_y
      @@offset_y
    end

    def self.width
      @@width
    end

    def self.height
      @@height
    end

    def self.capture
      capture_area 0, 0, @@width, @@height
    end

    def self.pixel x, y=nil
      if y.nil?
        y = x[1]
        x = x[0]
      end
      raise "Invalid coordinates" unless (0...@@width).include?(x) && (0...@@height).include?(y)
      return get_pixel_ext x, y
    end

    def self.wait_for xy, color, options={}, is=true
      x = xy[0]
      y = xy[1]

      @@defaults.each do |key, value|
        options[key] = value unless options.has_key? key
      end

      color = Color.parse color
      start_time = Time.now
      until is == color.tolerant_of?(pixel(x, y), options[:tolerance]) do
        return false if (Time.now - start_time) * 1000 >= options[:timeout]
        sleep(options[:period] * 0.001)
      end
      return true
    end

    def self.wait_for_not xy, color, options={}
      wait_for xy, color, options, false
    end

    def self.method_missing(m, *args, &block)
      capture.send(m, *args)
    end
  end
end