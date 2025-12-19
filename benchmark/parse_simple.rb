#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/yyjson'
require_relative 'support/data_generator'
require_relative 'support/helpers'
require 'json'
require 'benchmark/ips'

# Try to load Oj if available
begin
  require 'oj'
  HAS_OJ = true
rescue LoadError
  HAS_OJ = false
  puts "Note: Oj not installed. Install with: gem install oj"
end

# Small JSON (< 1KB)
small_data = BenchmarkDataGenerator.simple_hash(size: 10)
small_json = JSON.generate(small_data)

BenchmarkHelpers.print_data_info("Small Hash", small_data)
BenchmarkHelpers.compare_libraries("Parse Small JSON", small_json) do |x, data|
  x.report("YYJson") { YYJson.load(data) }
  x.report("JSON") { JSON.parse(data) }
  x.report("Oj") { Oj.load(data) } if HAS_OJ
end

# Medium JSON (10-100KB)
medium_data = BenchmarkDataGenerator.activerecord_array(count: 100)
medium_json = JSON.generate(medium_data)

BenchmarkHelpers.print_data_info("Medium Array", medium_data)
BenchmarkHelpers.compare_libraries("Parse Medium JSON", medium_json) do |x, data|
  x.report("YYJson") { YYJson.load(data) }
  x.report("JSON") { JSON.parse(data) }
  x.report("Oj") { Oj.load(data) } if HAS_OJ
end

# Large JSON (1MB+)
large_data = BenchmarkDataGenerator.large_json
large_json = JSON.generate(large_data)

BenchmarkHelpers.print_data_info("Large Hash", large_data)
BenchmarkHelpers.compare_libraries("Parse Large JSON", large_json) do |x, data|
  x.report("YYJson") { YYJson.load(data) }
  x.report("JSON") { JSON.parse(data) }
  x.report("Oj") { Oj.load(data) } if HAS_OJ
end

# Deeply nested structure
nested_data = BenchmarkDataGenerator.nested_hash(depth: 5, breadth: 3)
nested_json = JSON.generate(nested_data)

BenchmarkHelpers.print_data_info("Nested Hash", nested_data)
BenchmarkHelpers.compare_libraries("Parse Nested JSON", nested_json) do |x, data|
  x.report("YYJson") { YYJson.load(data) }
  x.report("JSON") { JSON.parse(data) }
  x.report("Oj") { Oj.load(data) } if HAS_OJ
end

puts "\n" + "=" * 60
puts "Benchmark Complete!"
puts "=" * 60
