require 'futscript/mouse_ext/mouse_ext'

module Futscript
  class Mouse
    @@mouse_events = { left: { down: 0x02, up: 0x04 }, right: { down: 0x08, up: 0x10 }, middle: { down: 0x20, up: 0x40 } }

    @@paths = []

    @@polled = true
    @@polling_rate = 125.0
    @@polling_period = 1.0 / @@polling_rate
    
    @@defaults = { scale_speed: 1.0, polled: true }

    def self.defaults
      @@defaults
    end
    
    def self.polling_rate
      @polling_rate
    end

    def self.polling_rate= value
      @polling_rate = value
      @@polling_period = 1.0 / value
    end

    def self.wait_for_poll
      return unless @@defaults[:polled]
      time_f = Time.now.to_f
      poll_count = time_f / @@polling_period
      sleep(@@polling_period - (poll_count - poll_count.to_i) * @@polling_period)
    end

    def self.add_paths paths
      @@paths += paths
    end

    def self.position=new_pos
      set_position new_pos[0], new_pos[1]
    end

    def self.position
      raw = raw_position
      [ raw[0] - Screen.offset_x, raw[1] - Screen.offset_y ]
    end

    def self.set_position x, y
      set_raw_position x + Screen.offset_x, y + Screen.offset_y
    end



    def self.teleport x, y
      pos = position
      teleport_relative x - pos[0], y - pos[1]
    end

    def self.teleport_relative dx, dy
      wait_for_poll

      teleport_relative_unpolled dx, dy
    end

    def self.move_relative dx, dy, scale_speed=nil
      scale_speed = @@defaults[:scale_speed] if scale_speed.nil?
      suitable_paths = []
      tolerance = 0.5
      i = 0
      loop do
        suitable_paths = @@paths.select { |p| 
          tolerant?(dx.abs, p['destination']['x'], tolerance) &&
          tolerant?(dy.abs, p['destination']['y'], tolerance)
        }

        raise "Could not find path for #{dx},#{dy}" if i > 100

        tolerance *= 1.2
        i += 1
        puts suitable_paths.count
        break unless (suitable_paths.count < 10 && !(tolerance > 4 && suitable_paths.count > 0))
      end

      path_data = suitable_paths[Random.rand(suitable_paths.count)]

      # MoveCursorUsingPath
      scale_x = (dx == 0 || path_data['destination']['x'] == 0 ? 1.0 : dx.to_f / path_data['destination']['x'])
      scale_y = (dy == 0 || path_data['destination']['y'] == 0 ? 1.0 : dy.to_f / path_data['destination']['y'])
      path = path_data['path']

      # FollowPath
      scale_speed = 0.1 if scale_speed < 0.1
      position_x = 0
      position_y = 0
      path_index = 0
      previous_time = 0

      end_time = path[path.length - 1][0]

      temp_x = 0
      temp_y = 0

      time = 8 * scale_speed
      while time <= end_time + 8
        tdx = 0
        tdy = 0

        while path_index < path.length && path[path_index][0] < time
          coords = path[path_index]
          tdx += coords[1] - (position_x + tdx)
          tdy += coords[2] - (position_y + tdy)
          previous_time = path[path_index][0]
          path_index += 1
        end

        temp_x = ((position_x + tdx) * scale_x).round - (position_x * scale_x).round
        temp_y = ((position_y + tdy) * scale_y).round - (position_y * scale_y).round

        teleport_relative(temp_x, temp_y)

        position_x += tdx
        position_y += tdy

        time += 8 * scale_speed
      end
    end

    def self.move x, y, scale_speed=nil
      pos = position
      move_relative x - pos[0], y - pos[1], scale_speed
    end

    def self.tolerant? dest, path_dest, tolerance=0.25
      (dest - dest * (tolerance / 4) - 5 <= path_dest) && (path_dest <= dest + dest * tolerance + 5)
    end

    def self.left_click sec=0.0
      click sec, :left
    end

    def self.right_click sec=0.0
      click sec, :right
    end

    def self.click sec=0.0, key=:left
      button key, :down
      sleep sec
      button key, :up
    end

    def self.button key, action
      raise "Invalid key" if @@mouse_events[key].nil?
      raise "Invalid action" if @@mouse_events[key][action].nil?

      wait_for_poll
      current_pos = self.raw_position
      self.event(@@mouse_events[key][action], current_pos[0], current_pos[1], 0)
    end
  end
end