require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'rake/clean'
require 'yard'
require 'yard/rake/yardoc_task'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(--format=progress --color)
end

task :default => :spec

YARD::Rake::YardocTask.new(:yard) do |yd|
  yd.options += ['--yardopts', '.yardopts']
end

CLOBBER.include 'pkg', 'Gemfile.lock', '.yardoc'
CLEAN.include 'doc'
