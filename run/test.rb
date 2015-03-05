require 'futscript.rb'
require 'json'

include Futscript


class Mouse
  
end

Screen.defaults[:timeout] = 1000
Screen.defaults[:tolerance] = 10
Mouse.defaults[:scale_speed] = 0.5

Mouse.add_paths JSON.parse(File.read('run/paths.json'))

Mouse.move 100, 100
