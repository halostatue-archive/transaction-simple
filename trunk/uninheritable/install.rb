begin
  require 'install-pkg'
rescue
  require './install-pkg.rb'
end

include InstallPkg

  # there are no dependencies
InstallPkg.install_pkg("Uninheritable")
