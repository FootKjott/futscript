# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'screen_ext'

# The destination
dir_config(extension_name)

$LOCAL_LIBS << '-lgdi32'

# Do the work
create_makefile(extension_name)