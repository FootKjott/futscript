require 'futscript/keyboard_ext/keyboard_ext'

module Futscript
  class Keyboard
    @@keybd_events = { down: 0, up: 2 }
    @@keys = Hash.new do |hash, key|
      key = key.to_s
      keyresult = -1
      if key.to_s.length == 1
        keyresult = self.char_to_key(key.to_s.ord)
      else
        match = /F([\d]+)/.match(key)
        unless match.nil?
          f_num = match[1].to_i
          keyresult = f_num + 0x6F if (1..12).include?(f_num)
        end
      end
      raise "Invalid character key #{key}" if keyresult == -1
      hash[key] = keyresult
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

    @@hotkeys = Hash.new

    @@hotkey_thread = nil

    @@polled = true
    @@polling_rate = 200.0
    @@polling_period = 1.0 / @@polling_rate

    def self.parse_key key_code
      case key_code
      when Integer
        key_code
      when Symbol
        @@keys[key_code]
      when String
        @@keys[key_code]
      else
        raise "Invalid key_code type"
      end
    end

    def self.hotkeys
      @@hotkeys
    end
    
    def self.polled
      @@polled
    end

    def self.polled= value
      @@polled = value
    end
    
    def self.polling_rate
      @polling_rate
    end

    def self.polling_rate= value
      @polling_rate = value
      @@polling_period = 1.0 / value
    end

    def self.wait_for_poll
      return unless @@polled
      time_f = Time.now.to_f
      poll_count = time_f / @@polling_period
      sleep(@@polling_period - (poll_count - poll_count.to_i) * @@polling_period)
    end

    def self.type str, wait_sec=0.1033, std_deviation=0.0231
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
          tap_key @@keys[char] % 256, wait_sec.distribute(std_deviation)
          sleep(wait_sec.distribute(std_deviation))
        end
      end
      if shift_down
        key @@keys["SHIFT"], :up
      end
    end

    def self.tap_key key_code, sec=0.0
      key key_code, :down
      sleep sec
      key key_code, :up
    end

    # Key codes: http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx
    def self.key key_code, action
      key_code = parse_key key_code
      
      raise "Invalid key action type" if @@keybd_events[action].nil?
      self.event(key_code, @@keybd_events[action])
    end

    def self.key_down? key_code
      key_code = parse_key key_code
      keycode_down? key_code
    end

    def self.key_was_down? key_code
      key_code = parse_key key_code
      keycode_was_down? key_code
    end

    def self.start_message_loop
      return unless @@hotkey_thread.nil?
      ObjectSpace.define_finalizer( self, proc { unhook } )
      Thread.new do 
        Keyboard.hook Proc.new { |key, action|
          hook_used = false
          if action == 0x0100
            @@hotkeys.each do |hkey, reaction|
              if key % 256 == hkey % 256
                reaction.call
                hook_used = true
              end
            end
          end
          hook_used
        }
      end
    end

    def self.hotkey key_code, &block
      start_message_loop
      @@hotkeys[@@keys[key_code]] = block
    end
  end
end