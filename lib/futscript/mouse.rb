require 'futscript/mouse_ext/mouse_ext'

module Futscript
  class Mouse
    @@mouse_events = { left: { down: 0x02, up: 0x04 }, right: { down: 0x08, up: 0x10 }, middle: { down: 0x20, up: 0x40 } }

    def self.position=new_pos
      self.set_position new_pos[0], new_pos[1]
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
      current_pos = self.position
      self.event(@@mouse_events[key][action], current_pos[0], current_pos[1], 0)
    end
  end
end