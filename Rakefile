require "bundler/gem_tasks"
require 'rake/clean'
require 'yard'
require 'yard/rake/yardoc_task'

CLOBBER.include 'pkg', 'Gemfile.lock', '.yardoc'
CLEAN.include 'doc'

task :default => :spec

task :spec do
  $LOAD_PATH.unshift(File.expand_path('lib'))
  
  files = []
  files.concat Dir["test/**/test_*.rb"]
  files.concat Dir["test/**/spec_*.rb"]
  files.concat Dir["spec/**/spec_*.rb"]
  files.concat Dir["spec/**/*_spec.rb"]

  if defined?(MACRUBY_VERSION)
    require 'mac_bacon'
    files.each { |file| load file}
    Bacon.run
  else
    require 'bacon'
    Bacon.summary_on_exit
    files.each { |file| load file}
  end
end

YARD::Rake::YardocTask.new(:yard) do |yd|
  yd.options += ['--yardopts', '.yardopts']
end
