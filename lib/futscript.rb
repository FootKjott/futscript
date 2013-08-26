require "Win32API"
%w(common version image keyboard mouse color screen).each do |dep|
  require "futscript/#{dep}"
end

module Futscript
  
end
