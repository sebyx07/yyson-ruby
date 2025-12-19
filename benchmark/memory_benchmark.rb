#!/usr/bin/env ruby
# frozen_string_literal: true

# Memory benchmark comparing YYJson, JSON gem, and Oj
#
# Usage:
#   ruby benchmark/memory_benchmark.rb
#
# Requirements:
#   gem install memory_profiler

require 'bundler/setup'
require 'json'

begin
  require 'memory_profiler'
  HAS_MEMORY_PROFILER = true
rescue LoadError
  HAS_MEMORY_PROFILER = false
  puts "Note: Install memory_profiler gem for detailed memory analysis"
  puts "  gem install memory_profiler"
  puts
end

begin
  require 'oj'
  HAS_OJ = true
rescue LoadError
  HAS_OJ = false
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../ext', __dir__)
require 'yyjson'

# Force GC for accurate measurements
def gc_compact
  GC.start(full_mark: true, immediate_sweep: true)
  GC.compact if GC.respond_to?(:compact)
end

# Measure memory usage of a block
def measure_memory
  gc_compact
  before = GC.stat[:heap_live_slots]
  yield
  gc_compact
  after = GC.stat[:heap_live_slots]
  after - before
end

# Generate test data
def generate_twitter_like(count = 100)
  {
    "statuses" => Array.new(count) do |i|
      {
        "id" => 1234567890 + i,
        "id_str" => (1234567890 + i).to_s,
        "text" => "This is tweet number #{i}. #ruby #json #benchmark",
        "created_at" => "Mon Jan 15 10:30:00 +0000 2024",
        "user" => {
          "id" => 100000 + i,
          "name" => "User #{i}",
          "screen_name" => "user#{i}",
          "followers_count" => rand(1000),
          "verified" => i < 10
        },
        "retweet_count" => rand(100),
        "favorite_count" => rand(500)
      }
    end
  }.to_json
end

def generate_large_array(count = 10000)
  Array.new(count) { |i| i }.to_json
end

def generate_nested_objects(depth = 10)
  obj = { "value" => 42, "name" => "leaf" }
  depth.times { |i| obj = { "level_#{i}" => obj, "data" => "level #{i}" } }
  obj.to_json
end

def generate_string_heavy(count = 100)
  {
    "items" => Array.new(count) do |i|
      {
        "title" => "Item #{i}: Lorem ipsum dolor sit amet",
        "description" => "Consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.",
        "tags" => ["tag_#{i}", "ruby", "json", "benchmark"]
      }
    end
  }.to_json
end

puts "=" * 70
puts "YYJson Memory Benchmark"
puts "=" * 70
puts
puts "Ruby version: #{RUBY_VERSION}"
puts "YYJson version: #{YYJson::VERSION}"
puts "JSON version: #{JSON::VERSION}" if defined?(JSON::VERSION)
puts "Oj version: #{Oj::VERSION}" if HAS_OJ
puts

# Test data
TWITTER_JSON = generate_twitter_like(100)
LARGE_ARRAY_JSON = generate_large_array(10000)
NESTED_JSON = generate_nested_objects(20)
STRING_HEAVY_JSON = generate_string_heavy(100)

puts "Test data sizes:"
puts "  Twitter-like (100):  #{TWITTER_JSON.bytesize} bytes"
puts "  Large array (10K):   #{LARGE_ARRAY_JSON.bytesize} bytes"
puts "  Nested (depth 20):   #{NESTED_JSON.bytesize} bytes"
puts "  String-heavy (100):  #{STRING_HEAVY_JSON.bytesize} bytes"
puts

# Simple memory measurement (heap slots)
puts "=" * 70
puts "HEAP SLOTS ALLOCATED (lower is better)"
puts "=" * 70
puts

test_cases = {
  "Twitter-like (100 items)" => TWITTER_JSON,
  "Large integer array (10K)" => LARGE_ARRAY_JSON,
  "Nested objects (depth 20)" => NESTED_JSON,
  "String-heavy (100 items)" => STRING_HEAVY_JSON
}

test_cases.each do |name, json|
  puts "#{name}:"

  # Warm up
  3.times do
    JSON.parse(json)
    YYJson.load(json)
    Oj.load(json) if HAS_OJ
  end
  gc_compact

  json_slots = measure_memory { 10.times { JSON.parse(json) } } / 10
  yyjson_slots = measure_memory { 10.times { YYJson.load(json) } } / 10
  oj_slots = HAS_OJ ? measure_memory { 10.times { Oj.load(json) } } / 10 : 0

  puts "  JSON:   #{json_slots} slots"
  puts "  YYJson: #{yyjson_slots} slots (#{((yyjson_slots.to_f / json_slots - 1) * 100).round(1)}% vs JSON)"
  puts "  Oj:     #{oj_slots} slots" if HAS_OJ
  puts
end

# Test frozen string optimization
puts "=" * 70
puts "FROZEN STRING VERIFICATION"
puts "=" * 70
puts

result = YYJson.load('{"key": "value", "nested": {"inner": "data"}}')
puts "Hash keys frozen: #{result.keys.all?(&:frozen?)}"
puts "String values frozen (default): #{result.values.select { |v| v.is_a?(String) }.all?(&:frozen?)}"

result_freeze = YYJson.load('{"key": "value"}', freeze: true)
puts "String values frozen (freeze: true): #{result_freeze['key'].frozen?}"
puts

# Test string interning (deduplication)
puts "=" * 70
puts "STRING INTERNING TEST"
puts "=" * 70
puts

# Parse array of objects with repeated keys
json_with_repeated_keys = [
  {"name" => "Alice", "age" => 30},
  {"name" => "Bob", "age" => 25},
  {"name" => "Charlie", "age" => 35}
].to_json

result = YYJson.load(json_with_repeated_keys)
keys = result.flat_map(&:keys)
unique_key_ids = keys.map(&:object_id).uniq

puts "Total keys: #{keys.size}"
puts "Unique object_ids: #{unique_key_ids.size}"
puts "Keys are interned (shared): #{unique_key_ids.size < keys.size}"
puts

# Detailed memory profiling (if available)
if HAS_MEMORY_PROFILER
  puts "=" * 70
  puts "DETAILED MEMORY PROFILE (Twitter-like data)"
  puts "=" * 70
  puts

  puts "JSON.parse:"
  report = MemoryProfiler.report { JSON.parse(TWITTER_JSON) }
  puts "  Total allocated: #{report.total_allocated_memsize} bytes"
  puts "  Total retained:  #{report.total_retained_memsize} bytes"
  puts "  Objects allocated: #{report.total_allocated}"
  puts

  puts "YYJson.load:"
  report = MemoryProfiler.report { YYJson.load(TWITTER_JSON) }
  puts "  Total allocated: #{report.total_allocated_memsize} bytes"
  puts "  Total retained:  #{report.total_retained_memsize} bytes"
  puts "  Objects allocated: #{report.total_allocated}"
  puts

  if HAS_OJ
    puts "Oj.load:"
    report = MemoryProfiler.report { Oj.load(TWITTER_JSON) }
    puts "  Total allocated: #{report.total_allocated_memsize} bytes"
    puts "  Total retained:  #{report.total_retained_memsize} bytes"
    puts "  Objects allocated: #{report.total_allocated}"
    puts
  end
end

# Memory usage for many parses
puts "=" * 70
puts "MEMORY GROWTH TEST (1000 parses)"
puts "=" * 70
puts

gc_compact
before_json = GC.stat[:heap_live_slots]
1000.times { JSON.parse(TWITTER_JSON) }
gc_compact
after_json = GC.stat[:heap_live_slots]

gc_compact
before_yyjson = GC.stat[:heap_live_slots]
1000.times { YYJson.load(TWITTER_JSON) }
gc_compact
after_yyjson = GC.stat[:heap_live_slots]

puts "JSON:   #{after_json - before_json} slots growth"
puts "YYJson: #{after_yyjson - before_yyjson} slots growth"
puts

puts "Memory benchmark complete!"
