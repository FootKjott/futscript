require 'futscript/screen_ext/screen_ext'

module Futscript
  class Screen
    def self.offset_x
      return @@offset_x
    end

    def self.offset_y
      return @@offset_y
    end

    def self.width
      return @@width
    end

    def self.height
      return @@height
    end

    def self.capture
      capture_area 0, 0, @@width, @@height
    end

    def self.get_pixel x, y
      raise "Invalid coordinates" unless (0...@@width).include?(x) && (0...@@height).include?(y)
      return get_pixel_ext x, y
    end

    def self.wait_for_px x, y, color, tolerance=5, timeout=100, ms_per_screenshot=50, is=true
      color = Color.parse color
      start_time = Time.now.to_i
      until is == color.is_tolerant_of(get_pixel(x, y), tolerance) do
        return false if Time.now.to_i - start_time >= timeout
        sleep(ms_per_screenshot * 0.001)
      end
      return true
    end

    def self.wait_for_px_not x, y, color, tolerance=5, timeout=100, ms_per_screenshot=50
      wait_for_px x, y, color, tolerance, timeout, ms_per_screenshot, false
    end

    def self.method_missing(m, *args, &block)
      capture.send(m, *args)
    end
  end
end