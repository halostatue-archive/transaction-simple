Gem::Specification.new do |s|
  s.name = %q{transaction-simple)
  s.version = %q{1.1.2}
  s.summary = %q{Simple object transaction support for Ruby}
  s.platform = Gem::Platform::RUBY

  s.has_rdoc = true

  s.test_suite_file = %w{tests/tests.rb}

  s.autorequire = %q{transaction/simple}
  s.require_paths = %w{lib}

  s.files = Dir.glob("**/*").delete_if do |item|
    item.include?("CVS") or item.include?(".svn") or
    item == "install.rb" or item =~ /~$/ or
    item =~ /gem(?:spec)?$/
  end

  s.author = %q{Austin Ziegler}
  s.email = %q{transaction-simple@halostatue.ca}
  s.rubyforge_project = %q(trans-simple)
  s.homepage = %q{http://rubyforge.org/projects/trans-simple}
  s.description = File.read("README")
end
