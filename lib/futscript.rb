require "Win32API"
%w(common version image keyboard mouse screen).each do |dep|
  require "futscript/#{dep}"
end

module Futscript
  
end
