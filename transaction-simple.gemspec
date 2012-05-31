$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "transaction/simple/version"

Gem::Specification.new "transaction-simple", Transaction::Simple::VERSION do |s|
  s.summary = "Simple object transaction support for Ruby."
  s.authors = ["Austin Ziegler"]
  s.email = "austin@rubyforge.org"
  s.homepage = "https://github.com/halostatue/transaction-simple"
  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
end
