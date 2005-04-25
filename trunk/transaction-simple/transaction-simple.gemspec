Gem::Specification.new do |s|
  s.name = %q(transaction-simple)
  s.version = %q(0.0.0) # Overridden in the rakefile
  s.author = %q{Austin Ziegler}
  s.email = %q{transaction-simple@halostatue.ca}
  s.homepage = %q{http://rubyforge.org/projects/trans-simple}
  s.rubyforge_project = %q(trans-simple)

  s.files = Dir.glob("**/*").delete_if do |item|
    item.include?("CVS") or item.include?(".svn") or
    item == "install.rb" or item =~ /~$/ or
    item =~ /gem(?:spec)?$/
  end

  s.summary = %q{Simple object transaction support for Ruby.}

  s.required_ruby_version = %(>=1.8.1)

# s.executables =
# s.bindir =

  s.test_files = %w{tests/tests.rb}

  s.autorequire = %q{transaction/simple}
  s.require_paths = %w{lib}

  description = []
  File.open("README") do |file|
    file.each do |line|
      line.chomp!
      break if line.empty?
      description << "#{line.gsub(/\[\d\]/, '')}"
    end
  end
  s.description = description[2..-1].join(" ")

  s.has_rdoc = true
  s.rdoc_options = ["--title", "Transaction::Simple -- Active Object Transaction Support for Ruby", "--main", "Transaction::Simple", "--line-numbers"]
  s.extra_rdoc_files = %w(Readme Changelog Install)
end
