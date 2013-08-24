module Futscript
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

    attr_accessor :keys

    def self.type str, speed=1.2
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

    def self.tap_key key_code, ms=0
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