# frozen_string_literal: true

require 'rake/extensiontask'
require 'rake/testtask'

# Extension compilation task
Rake::ExtensionTask.new('yyjson') do |ext|
  ext.lib_dir = 'lib/yyjson'
  ext.ext_dir = 'ext/yyjson'
end

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
  t.warning = false
end

# Ensure extension is compiled before running tests
task test: :compile

# Benchmark tasks
namespace :benchmark do
  desc 'Run parsing benchmarks'
  task :parse do
    ruby 'benchmark/parse_simple.rb'
  end

  desc 'Run generation benchmarks'
  task :generate do
    ruby 'benchmark/generate_simple.rb'
  end

  desc 'Run round-trip benchmarks'
  task :round_trip do
    ruby 'benchmark/round_trip.rb'
  end

  desc 'Run memory benchmarks'
  task :memory do
    ruby 'benchmark/memory_benchmark.rb'
  end

  desc 'Run all benchmarks'
  task all: [:parse, :generate, :round_trip]
end

desc 'Run all benchmarks'
task benchmark: 'benchmark:all'

# Clean task
desc 'Remove compiled files and build artifacts'
task :clean do
  rm_rf 'lib/yyjson/yyjson.so'
  rm_rf 'lib/yyjson/yyjson.bundle'
  rm_rf Dir.glob('ext/yyjson/*.o')
  rm_rf 'ext/yyjson/Makefile'
  rm_rf 'ext/yyjson/mkmf.log'
  rm_rf 'pkg'
  rm_rf 'tmp'
end

# Clobber task - clean + remove vendor
desc 'Remove all generated files including vendor directory'
task clobber: :clean do
  rm_rf 'ext/yyjson/vendor'
end

# Console task for interactive testing
desc 'Start an IRB session with YYJson loaded'
task :console do
  require 'irb'
  require 'irb/completion'
  require_relative 'lib/yyjson'
  ARGV.clear
  IRB.start
end

# Build gem
desc 'Build the gem package'
task :build do
  system 'gem build yyjson.gemspec'
end

# Install gem locally
desc 'Install the gem locally'
task install: :build do
  system 'gem install yyjson-*.gem'
end

# Default task
task default: :test
