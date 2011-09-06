require "bundler/gem_tasks"
require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(--format=progress --color)
end

task :default => :spec

desc 'Remove generated code'
task :clobber do
  rm_rf './pkg'
end
