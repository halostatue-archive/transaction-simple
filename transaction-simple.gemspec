# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "transaction-simple"
  s.version = "1.4.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Austin Ziegler"]
  s.date = "2012-08-26"
  s.description = "Transaction::Simple provides a generic way to add active transaction support to\nobjects. The transaction methods added by this module will work with most\nobjects, excluding those that cannot be Marshal-ed (bindings, procedure\nobjects, IO instances, or singleton objects).\n\nThe transactions supported by Transaction::Simple are not associated with any\nsort of data store. They are \"live\" transactions occurring in memory on the\nobject itself. This is to allow \"test\" changes to be made to an object before\nmaking the changes permanent.\n\nTransaction::Simple can handle an \"infinite\" number of transaction levels\n(limited only by memory). If I open two transactions, commit the second, but\nabort the first, the object will revert to the original version.\n\nTransaction::Simple supports \"named\" transactions, so that multiple levels of\ntransactions can be committed, aborted, or rewound by referring to the\nappropriate name of the transaction. Names may be any object except nil.\n\nTransaction groups are also supported. A transaction group is an object wrapper\nthat manages a group of objects as if they were a single object for the purpose\nof transaction management. All transactions for this group of objects should be\nperformed against the transaction group object, not against individual objects\nin the group.\n\nVersion 1.4.0 of Transaction::Simple adds a new post-rewind hook so that\ncomplex graph objects of the type in tests/tc_broken_graph.rb can correct\nthemselves.\n\nVersion 1.4.0.1 just fixes a simple bug with #transaction method handling\nduring the deprecation warning.\n\nVersion 1.4.0.2 is a small update for people who use Transaction::Simple in\nbundler (adding lib/transaction-simple.rb) and other scenarios where having Hoe\nas a runtime dependency (a bug fixed in Hoe several years ago, but not visible\nin Transaction::Simple because it has not needed a re-release). All of the\nfiles internally have also been marked as UTF-8, ensuring full Ruby 1.9\ncompatibility."
  s.email = ["austin@rubyforge.org"]
  s.extra_rdoc_files = ["History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "Licence.rdoc", "README.rdoc"]
  s.files = ["History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "lib/transaction-simple.rb", "lib/transaction/simple.rb", "lib/transaction/simple/group.rb", "lib/transaction/simple/threadsafe.rb", "lib/transaction/simple/threadsafe/group.rb", "test/test_broken_graph.rb", "test/test_transaction_simple.rb", "test/test_transaction_simple_group.rb", "test/test_transaction_simple_threadsafe.rb", ".gemtest"]
  s.homepage = "http://trans-simple.rubyforge.org/"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "trans-simple"
  s.rubygems_version = "1.8.15"
  s.summary = "Transaction::Simple provides a generic way to add active transaction support to objects"
  s.test_files = ["test/test_broken_graph.rb", "test/test_transaction_simple.rb", "test/test_transaction_simple_group.rb", "test/test_transaction_simple_threadsafe.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>, ["~> 3.0"])
    else
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe>, ["~> 3.0"])
  end
end
