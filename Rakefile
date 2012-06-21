# -*- ruby encoding: utf-8 -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :doofus
Hoe.plugin :gemspec
Hoe.plugin :rubyforge
Hoe.plugin :git

Hoe.spec 'transaction-simple' do
  self.rubyforge_name = "trans-simple"

  developer('Austin Ziegler', 'austin@rubyforge.org')

  self.remote_rdoc_dir = '.'
  self.rsync_args << ' --exclude=statsvn/'

  self.history_file = 'History.rdoc'
  self.readme_file = 'README.rdoc'
  self.extra_rdoc_files = FileList["*.rdoc"].to_a
end

# vim: syntax=ruby
