module Futscript
  class Screen
    @@CreateDC = Win32API.new('gdi32', 'CreateDC', ['S', 'S', 'S', 'I'], 'I')  
    @@CreateCompatibleDC = Win32API.new('gdi32', "CreateCompatibleDC", ["I"], "I")
    @@CreateCompatibleBitmap = Win32API.new('gdi32', "CreateCompatibleBitmap", ["I", "I", "I"], "I")
    @@SelectObject = Win32API.new('gdi32', "SelectObject", ["I", "I"], "I")
    @@BitBlt = Win32API.new('gdi32', "BitBlt", ["I", "I", "I", "I", "I", "I", "I", "I", "I"], "I")
    @@DeleteDC = Win32API.new('gdi32', "DeleteDC", ["I"], "I")
    @@GetPixel = Win32API.new('gdi32', 'GetPixel', ["I", "I", "I"], "I")
    @@GetDIBits = Win32API.new('gdi32', 'GetDIBits', ["I", "I", "I", "I", "P", "P" , "I"], "I")
    @@DeleteObject = Win32API.new('gdi32', 'DeleteObject', ["I"], "I")
    @@GetSystemMetrics = Win32API.new('user32', 'GetSystemMetrics', ["I"], "I")

    @@hdc = @@CreateDC.call("DISPLAY", nil, nil, 0)
    @@offset_x = @@GetSystemMetrics.call(76)
    @@offset_y = @@GetSystemMetrics.call(77)
    @@width = @@GetSystemMetrics.call(78)
    @@height = @@GetSystemMetrics.call(79)

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

    def self.capture_all_screens
      capture_screen_area 0, 0, @@width, @@height
    end

    def self.capture_screen_area x, y, width, height
      hdc_dest = @@CreateCompatibleDC.call(@@hdc)
      h_bitmap = @@CreateCompatibleBitmap.call(@@hdc.to_i, width, height)
      @@SelectObject.call(hdc_dest, h_bitmap)
      @@BitBlt.call(hdc_dest, 0, 0, width, height, @@hdc, x + @@offset_x, y + @@offset_y, 0x40000000 | 0x00CC0020)
      bmi = [40, width, height, 1, 24].pack("LllSS").ljust(44, "\0")
      @@GetDIBits.call(hdc_dest, h_bitmap, 0, height, nil, bmi, 0x00) #Sets BITMAPINFO bmi
      bmiarr = bmi.unpack("LllSSLLllLLCCCC")
      bmpbuffer = "\0" * bmiarr[6]
      @@GetDIBits.call(hdc_dest, h_bitmap, 0, height, bmpbuffer, bmi, 0x00) #Fills bmpbuffer
      @@DeleteDC.call(hdc_dest)
      @@DeleteObject.call(h_bitmap)
      return Image.from_bmi_data(bmiarr, bmpbuffer)
    end

    def self.get_pixel x, y
      raise "Invalid coordinates" unless (0...@@width).include?(x) && (0...@@height).include?(y)
      colorref = @@GetPixel.call(@@hdc, x + @@offset_x, y + @@offset_y)
      return Color.new(colorref % 256, (colorref / 256) % 256, (colorref / 65536) % 256)
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
      capture_all_screens.send(m, *args)
    end
  end
end