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
end

# Small Hash
small_data = BenchmarkDataGenerator.simple_hash(size: 10)

BenchmarkHelpers.print_data_info("Small Hash", small_data)
BenchmarkHelpers.compare_libraries("Generate Small JSON", small_data) do |x, data|
  x.report("YYJson") { YYJson.dump(data) }
  x.report("JSON") { JSON.generate(data) }
  x.report("Oj") { Oj.dump(data) } if HAS_OJ
end

# Medium Array
medium_data = BenchmarkDataGenerator.activerecord_array(count: 100)

BenchmarkHelpers.print_data_info("Medium Array", medium_data)
BenchmarkHelpers.compare_libraries("Generate Medium JSON", medium_data) do |x, data|
  x.report("YYJson") { YYJson.dump(data) }
  x.report("JSON") { JSON.generate(data) }
  x.report("Oj") { Oj.dump(data) } if HAS_OJ
end

# Large Hash
large_data = BenchmarkDataGenerator.large_json

BenchmarkHelpers.print_data_info("Large Hash", large_data)
BenchmarkHelpers.compare_libraries("Generate Large JSON", large_data) do |x, data|
  x.report("YYJson") { YYJson.dump(data) }
  x.report("JSON") { JSON.generate(data) }
  x.report("Oj") { Oj.dump(data) } if HAS_OJ
end

# Nested Hash
nested_data = BenchmarkDataGenerator.nested_hash(depth: 5, breadth: 3)

BenchmarkHelpers.print_data_info("Nested Hash", nested_data)
BenchmarkHelpers.compare_libraries("Generate Nested JSON", nested_data) do |x, data|
  x.report("YYJson") { YYJson.dump(data) }
  x.report("JSON") { JSON.generate(data) }
  x.report("Oj") { Oj.dump(data) } if HAS_OJ
end

# Pretty printing
puts "\n" + "=" * 60
puts "Pretty Printing Comparison"
puts "=" * 60

data = BenchmarkDataGenerator.api_response(items: 20)

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  x.report("YYJson (pretty)") { YYJson.dump(data, pretty: true) }
  x.report("JSON (pretty)") { JSON.pretty_generate(data) }
  x.report("Oj (pretty)") { Oj.generate(data, indent: 2) } if HAS_OJ

  x.compare!
end

puts "\n" + "=" * 60
puts "Benchmark Complete!"
puts "=" * 60
