require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => [:clean_db, :test]

desc 'Remove the stale db file'
task :clean_db do
  `rm -f #{File.dirname(__FILE__)}/test/state_machine.sqlite3.db`
end

desc 'Test the acts as state machine plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end
