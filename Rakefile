require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'rake/clean'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(--format=progress --color)
end

task :default => :spec

CLOBBER.include 'pkg', 'Gemfile.lock'
