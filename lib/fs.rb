require "Win32API"

MessageBox = Win32API.new('user32', 'MessageBox', ['L', 'P', 'P', 'L'], 'I')  

Point = Struct.new(:x, :y)
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
    Point.new(arr[0], arr[1])
  end

  def self.cursor_pos=new_pos
    @@SetCursorPos.call(new_pos[:x], new_pos[:y]) == 0
  end

  def self.move_to destination, speed = 3, limit = 10000
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
    pos.x += xdif
    pos.y += ydif
    move_to pos, speed, 10000
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

print "hi"