# -*- ruby -*-


require 'rubygems'
require "rspec/core/rake_task"

# Hoe.plugin :compiler
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :racc
# Hoe.plugin :rubyforge
if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ruby'
  require 'hoe'
  Hoe.plugin :git
  Hoe.plugin :gemspec
  Hoe.plugin :bundler
  Hoe.plugin :gemcutter
  Hoe.plugins.delete :rubyforge
  Hoe.plugins.delete :test

  Hoe.spec 'profitbricks' do
    developer('Dominik Sander', 'git@dsander.de')

    self.readme_file = 'README.md'
    self.history_file = 'CHANGELOG.md'
    self.extra_deps << ["savon", "2.2.0"]
    self.licenses = ['MIT']
  end

  task :prerelease => [:clobber, :check_manifest, :test]
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/profitbricks/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
end
namespace :spec do
  RSpec::Core::RakeTask.new(:live) do |spec|
    spec.pattern = 'spec/live/*_spec.rb'
    spec.rspec_opts = ['--backtrace']
  end
end


task :default => :spec
task :test => :spec
