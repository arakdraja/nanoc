# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'rake/testtask'

RuboCop::RakeTask.new(:rubocop)

Rake::TestTask.new(:test_all) do |t|
  t.test_files = Dir['test/**/test_*.rb']
  t.libs << 'test'
  t.verbose = false
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

task test: %i[spec test_all rubocop]
task test_ci: :test

task default: :test
