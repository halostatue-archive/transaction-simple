Gem::Specification.new do |s|
  s.name = %q(uninheritable)
  s.version = %q(1.0.3)
  s.summary = %q(Allows an object to declare itself as unable to be subclassed.)
  s.description = %q(A convenience module to make a class unable to be subclassed.)
  s.platform = Gem::Platform::RUBY

  s.has_rdoc          = true
  s.rdoc_options      = %w(--title Uninheritable --line-numbers)
  s.extra_rdoc_files  = %w(Changelog Install)

  s.test_suite_file = %w(tests/tests.rb)

  s.autorequire = %q(uninheritable)
  s.require_paths = %w(lib)

  s.files = Dir.glob("**/*").delete_if do |item|
    item.include?("CVS") or item.include?(".svn") or
    item == "install.rb" or item =~ /~$/ or
    item =~ /gem(?:spec)?$/
  end

  s.author = %q(Austin Ziegler)
  s.email = %q(austin@rubyforge.org)
  s.rubyforge_project = %q(trans-simple)
  s.homepage = %q(http://rubyforge.org/projects/trans-simple)
end
