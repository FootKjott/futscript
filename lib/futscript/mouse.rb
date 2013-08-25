module Futscript
  class Mouse
    @@SetCursorPos = Win32API.new('user32', 'SetCursorPos', ['L', 'L'], 'I')  
    @@GetCursorPos = Win32API.new('user32', 'GetCursorPos', ['P'], 'I')
    @@mouse_event = Win32API.new('user32', 'mouse_event', ['I', 'I', 'I', 'I'], 'V')  

    @@mouse_events = { left: { down: 0x02, up: 0x04 }, right: { down: 0x08, up: 0x10 }, middle: { down: 0x20, up: 0x40 } }
    
    def self.cursor_pos
      str = [0, 0].pack('ll')
      @@GetCursorPos.call(str)
      arr = str.unpack('ll')
      Point.new(arr[0] - Screen.offset_x, arr[1] -  Screen.offset_y)
    end

    def self.cursor_pos=new_pos
      @@SetCursorPos.call(Screen.offset_x + new_pos[:x], Screen.offset_y + new_pos[:y])
    end

    def self.move_to x, y, speed=3
      x = Randy.rand(x) if x.is_a? Range
      y = Randy.rand(y) if y.is_a? Range

      raise "Invalid coordinates" unless (0...Screen.width).include?(x) && (0...Screen.height).include?(y)
      destination = Point.new(x, y)
      maxrandy = Randy.rand(Randy.rand(50...80)...Randy.rand(120...150))
      until (current_pos = cursor_pos) == destination do 
        xdif = (current_pos.x - destination.x).abs + 1
        ydif = (current_pos.y - destination.y).abs + 1
        if Randy.rand(0...maxrandy) <= 100 * xdif / ydif
          current_pos.x += (destination.x - current_pos.x) <=> 0
        end
        if Randy.rand(0...maxrandy) <= 100 * ydif / xdif
          current_pos.y += (destination.y - current_pos.y) <=> 0
        end
        self.cursor_pos = current_pos
        sleep 0.1**speed 
      end
    end

    def self.move_from xdif, ydif, speed=3
      xdif = Randy.rand(xdif) if xdif.is_a? Range
      ydif = Randy.rand(ydif) if ydif.is_a? Range
      pos = cursor_pos
      move_to pos.x + xdif, pos.y + ydif, speed
      return pos
    end

    def self.left_click ms=0
      click ms, :left
    end

    def self.right_click ms=0
      click ms, :right
    end

    def self.click ms=0, key=:left
      ms = Randy.rand(ms) if ms.is_a? Range
      button key, :down
      sleep ms * 0.001
      button key, :up
    end

    def self.button key, action
      raise "Invalid key" if @@mouse_events[key].nil?
      raise "Invalid action" if @@mouse_events[key][action].nil?
      current_pos = cursor_pos
      @@mouse_event.call(@@mouse_events[key][action], current_pos.x, current_pos.y, 0, 0)
    end
  end
end