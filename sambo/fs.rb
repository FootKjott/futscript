require "Win32API"

MessageBox = Win32API.new('user32', 'MessageBox', ['L', 'P', 'P', 'L'], 'I')  

Point = Struct.new(:x, :y)
Color = Struct.new(:r, :g, :b)

$randy = Random.new

class Mouse
  @@SetCursorPos = Win32API.new('user32', 'SetCursorPos', ['L', 'L'], 'I')  
  @@GetCursorPos = Win32API.new('user32', 'GetCursorPos', ['P'], 'I')
  @@mouse_event = Win32API.new('user32', 'mouse_event', ['I', 'I', 'I', 'I'], 'V')  

  @@mouse_events = { left: { down: 0x02, up: 0x04 }, right: { down: 0x08, up: 0x10 } }
  
  def self.cursor_pos
    str = [0, 0].pack('ll')
    @@GetCursorPos.call(str)
    arr = str.unpack('ll')
    Point.new(arr[0] - Monitor.screen_offset_x, arr[1] -  Monitor.screen_offset_y)
  end

  def self.cursor_pos=new_pos
    @@SetCursorPos.call(Monitor.screen_offset_x + new_pos[:x], Monitor.screen_offset_y + new_pos[:y])
  end

  def self.move_to x, y, speed = 3, limit = 10000
    destination = Point.new(x, y)
    maxrandy = $randy.rand($randy.rand(50...80)...$randy.rand(120...150))
    until (current_pos = cursor_pos) == destination do 
      xdif = (current_pos.x - destination.x).abs + 1
      ydif = (current_pos.y - destination.y).abs + 1
      if $randy.rand(0...maxrandy) <= 100 * xdif / ydif
        current_pos.x += (destination.x - current_pos.x) <=> 0
      end
      if $randy.rand(0...maxrandy) <= 100 * ydif / xdif
        current_pos.y += (destination.y - current_pos.y) <=> 0
      end
      self.cursor_pos = current_pos
      limit -= 1
      if limit < 1
        throw "move_to hit its move limit"
      end
      sleep 0.1**speed 
    end
  end

  def self.move_from xdif, ydif, speed = 3, limit = 10000
    pos = cursor_pos
    move_to pos.x + xdif, pos.y + ydif, speed, 10000
    return pos
  end

  def self.left_click ms = 0
    click ms, :left
  end

  def self.right_click ms = 0
    click ms, :right
  end

  def self.click ms = 0, key = :left
    button key, :down
    sleep ms * 0.001
    button key, :up
  end

  def self.button key, action
    current_pos = cursor_pos
    @@mouse_event.call(@@mouse_events[key][action], current_pos.x, current_pos.y, 0, 0)
  end
end

class Keyboard
  @@keybd_event = Win32API.new('user32', 'keybd_event', ['I', 'I', 'I', 'I'], 'V')  
  @@keybd_events = { down: 0, up: 2 }
  @@VkKeyScan = Win32API.new('user32', 'VkKeyScan', ['I'], 'I')
  @@keys = Hash.new do |hash, key|
    if key.to_s.length == 1
      keyresult = @@VkKeyScan.call(key.to_s.ord)
      raise "Invalid character key #{key}" if keyresult == -1
      hash[key] = keyresult
    end
  end

  @@keys["BACK"] = 0x08
  @@keys["TAB"] = 0x09
  @@keys["ENTER"] = 0x0D
  @@keys["SHIFT"] = 0x10
  @@keys["CTRL"] = 0x11
  @@keys["CAPITAL"] = 0x14
  @@keys["ESCAPE"] = 0x1B
  @@keys["PAGEUP"] = 0x21
  @@keys["PAGEDOWN"] = 0x22
  @@keys["LEFT"] = 0x25
  @@keys["UP"] = 0x26
  @@keys["RIGHT"] = 0x27
  @@keys["DOWN"] = 0x28
  @@keys["PRTSCN"] = 0x2C
  @@keys["DELETE"] = 0x2E

  def self.keys
    return @@keys
  end

  def self.type str, speed = 1.2
    shift_down = false
    str.chars.each do |char|
      unless @@keys[char].nil?
        if @@keys[char] / 256 == 1
          unless shift_down
            key @@keys["SHIFT"], :down
            shift_down = true
          end
        else
          if shift_down
            key @@keys["SHIFT"], :up
            shift_down = false
          end
        end
        tap_key @@keys[char] % 256, 0.1**speed
        sleep(0.1**speed)
      end
    end
    if shift_down
      key @@keys["SHIFT"], :up
    end
  end

  def self.tap_key key_code, ms = 0
    key key_code, :down
    sleep ms*0.001
    key key_code, :up
  end

  # Key codes: http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx
  def self.key key_code, action
    case key_code
    when Integer
      key_code = key_code
    when Symbol
      key_code = @@keys[key_code]
    when String
      key_code = @@keys[key_code]
    else
      raise "Invalid key_code type"
    end
    raise "Invalid key_code value" if key_code.nil?
    raise "Invalid key action type" if @@keybd_events[action].nil?
    @@keybd_event.call(key_code, 0x45, @@keybd_events[action], 0)
  end
end

class Image
  def initialize width, height, bmi, data
    @width = width
    @height = height
    @bmi = bmi
    @data = data
  end

  def get_pixel x, y
    y = @height - y - 1
    raise "Invalid coordinates" unless (0..@width).include?(x) && (0..@height).include?(y)
    colorref = @data[(y * @width + x) * 3, 3].unpack('CCC')
    return Color.new(colorref[2], colorref[1], colorref[0])
  end
end

class Monitor
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
  @@screen_offset_x = @@GetSystemMetrics.call(76)
  @@screen_offset_y = @@GetSystemMetrics.call(77)
  @@screen_width = @@GetSystemMetrics.call(78)
  @@screen_height = @@GetSystemMetrics.call(79)

  def self.capture_all_screens
    capture_screen_area 0, 0, @@screen_width, @@screen_height
  end

  def self.screen_offset_x
    return @@screen_offset_x 
  end

  def self.screen_offset_y
    return @@screen_offset_y 
  end

  def self.capture_screen_area x, y, width, height
    hdc_dest = @@CreateCompatibleDC.call(@@hdc)
    h_bitmap = @@CreateCompatibleBitmap.call(@@hdc.to_i, width, height)
    @@SelectObject.call(hdc_dest, h_bitmap)
    @@BitBlt.call(hdc_dest, 0, 0, width, height, @@hdc, x + @@screen_offset_x, y + @@screen_offset_y, 0x40000000 | 0x00CC0020)
    bmi = [40, width, height, 1, 24].pack("LllSS").ljust(44, "\0")
    @@GetDIBits.call(hdc_dest, h_bitmap, 0, height, nil, bmi, 0x00) #Sets BITMAPINFO bmi
    bmiarr = bmi.unpack("LllSSLLllLLCCCC")
    bmpbuffer = "\0" * bmiarr[6]
    @@GetDIBits.call(hdc_dest, h_bitmap, 0, height, bmpbuffer, bmi, 0x00) #Fills bmpbuffer
    @@DeleteDC.call(hdc_dest)
    @@DeleteObject.call(h_bitmap)
    return Image.new(width, height, bmiarr, bmpbuffer)
  end

  def self.get_pixel x, y
    colorref = @@GetPixel.call(@@hdc, x + @@screen_offset_x, y + @@screen_offset_y)
    return Color.new(colorref % 256, (colorref / 256) % 256, (colorref / 65536) % 256)
  end
end
