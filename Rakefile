require "bundler/gem_tasks"
require "rake/testtask"
task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = true
  t.warning = true
end

# rdoc -x vendor -o rdoc

require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks
