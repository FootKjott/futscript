Dir['ext/futscript/*'].each do |d|
  ext_name = File.basename d
  puts "Compiling #{ext_name}... "
  puts `cd ext/futscript/#{ext_name} && extconf.rb`
  #puts "make any necessary changes to the makefile now"
  #gets
  puts `cd ext/futscript/#{ext_name} && make`
  puts
end
