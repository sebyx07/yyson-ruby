#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark comparing YYJson parsing performance against JSON gem and Oj
#
# Usage:
#   ruby benchmark/parse_benchmark.rb

require 'bundler/setup'
require 'benchmark/ips'
require 'json'

begin
  require 'oj'
  HAS_OJ = true
rescue LoadError
  HAS_OJ = false
  puts "Oj not available, skipping Oj benchmarks"
end

# Load YYJson from the built extension
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../ext', __dir__)
require 'yyjson'

# Generate test data
def generate_simple_object
  { "name" => "John Doe", "age" => 30, "active" => true, "score" => 95.5 }.to_json
end

def generate_nested_object
  {
    "user" => {
      "id" => 12345,
      "name" => "John Doe",
      "email" => "john@example.com",
      "profile" => {
        "bio" => "A software developer",
        "location" => "San Francisco",
        "website" => "https://example.com"
      }
    },
    "metadata" => {
      "created_at" => "2024-01-15T10:30:00Z",
      "updated_at" => "2024-01-20T14:45:00Z"
    }
  }.to_json
end

def generate_array_of_objects(count = 100)
  Array.new(count) do |i|
    {
      "id" => i,
      "name" => "User #{i}",
      "email" => "user#{i}@example.com",
      "active" => i.even?,
      "score" => rand * 100
    }
  end.to_json
end

def generate_large_array(count = 1000)
  Array.new(count) { |i| i }.to_json
end

def generate_string_heavy
  {
    "title" => "Lorem ipsum dolor sit amet",
    "description" => "Consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    "tags" => ["ruby", "json", "performance", "benchmark", "optimization"],
    "content" => "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
  }.to_json
end

def generate_twitter_like(count = 100)
  # Simulates typical API response with repeated keys (key caching benefit)
  {
    "statuses" => Array.new(count) do |i|
      {
        "id" => 1234567890 + i,
        "id_str" => (1234567890 + i).to_s,
        "text" => "This is tweet number #{i}. #ruby #json #benchmark",
        "created_at" => "Mon Jan 15 10:30:00 +0000 2024",
        "user" => {
          "id" => 100000 + i,
          "id_str" => (100000 + i).to_s,
          "name" => "User #{i}",
          "screen_name" => "user#{i}",
          "followers_count" => rand(1000),
          "friends_count" => rand(500),
          "verified" => i < 10
        },
        "retweet_count" => rand(100),
        "favorite_count" => rand(500),
        "favorited" => false,
        "retweeted" => false
      }
    end,
    "search_metadata" => {
      "completed_in" => 0.05,
      "max_id" => 1234567990,
      "max_id_str" => "1234567990",
      "count" => count
    }
  }.to_json
end

# Test data
SIMPLE_JSON = generate_simple_object
NESTED_JSON = generate_nested_object
ARRAY_JSON = generate_array_of_objects(100)
LARGE_ARRAY_JSON = generate_large_array(1000)
STRING_HEAVY_JSON = generate_string_heavy
TWITTER_JSON = generate_twitter_like(100)

puts "=" * 70
puts "YYJson Parsing Benchmark"
puts "=" * 70
puts
puts "Ruby version: #{RUBY_VERSION}"
puts "YYJson version: #{YYJson::VERSION}"
puts "JSON version: #{JSON::VERSION}" if defined?(JSON::VERSION)
puts "Oj version: #{Oj::VERSION}" if HAS_OJ
puts
puts "Test data sizes:"
puts "  Simple object:     #{SIMPLE_JSON.bytesize} bytes"
puts "  Nested object:     #{NESTED_JSON.bytesize} bytes"
puts "  Array (100 items): #{ARRAY_JSON.bytesize} bytes"
puts "  Large array:       #{LARGE_ARRAY_JSON.bytesize} bytes"
puts "  String heavy:      #{STRING_HEAVY_JSON.bytesize} bytes"
puts "  Twitter-like:      #{TWITTER_JSON.bytesize} bytes"
puts

# Verify correctness first
puts "Verifying correctness..."
[SIMPLE_JSON, NESTED_JSON, ARRAY_JSON, LARGE_ARRAY_JSON, STRING_HEAVY_JSON, TWITTER_JSON].each_with_index do |json, i|
  json_result = JSON.parse(json)
  yyjson_result = YYJson.load(json)

  if json_result == yyjson_result
    puts "  Test #{i + 1}: PASS"
  else
    puts "  Test #{i + 1}: FAIL"
    puts "    JSON:   #{json_result.inspect[0..100]}"
    puts "    YYJson: #{yyjson_result.inspect[0..100]}"
  end
end
puts

# Run benchmarks
puts "=" * 70
puts "BENCHMARK: Simple Object (#{SIMPLE_JSON.bytesize} bytes)"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(SIMPLE_JSON) }
  x.report("YYJson.load") { YYJson.load(SIMPLE_JSON) }
  x.report("Oj.load") { Oj.load(SIMPLE_JSON) } if HAS_OJ

  x.compare!
end

puts
puts "=" * 70
puts "BENCHMARK: Nested Object (#{NESTED_JSON.bytesize} bytes)"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(NESTED_JSON) }
  x.report("YYJson.load") { YYJson.load(NESTED_JSON) }
  x.report("Oj.load") { Oj.load(NESTED_JSON) } if HAS_OJ

  x.compare!
end

puts
puts "=" * 70
puts "BENCHMARK: Array of Objects (#{ARRAY_JSON.bytesize} bytes)"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(ARRAY_JSON) }
  x.report("YYJson.load") { YYJson.load(ARRAY_JSON) }
  x.report("Oj.load") { Oj.load(ARRAY_JSON) } if HAS_OJ

  x.compare!
end

puts
puts "=" * 70
puts "BENCHMARK: Large Integer Array (#{LARGE_ARRAY_JSON.bytesize} bytes)"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(LARGE_ARRAY_JSON) }
  x.report("YYJson.load") { YYJson.load(LARGE_ARRAY_JSON) }
  x.report("Oj.load") { Oj.load(LARGE_ARRAY_JSON) } if HAS_OJ

  x.compare!
end

puts
puts "=" * 70
puts "BENCHMARK: String-Heavy Object (#{STRING_HEAVY_JSON.bytesize} bytes)"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(STRING_HEAVY_JSON) }
  x.report("YYJson.load") { YYJson.load(STRING_HEAVY_JSON) }
  x.report("Oj.load") { Oj.load(STRING_HEAVY_JSON) } if HAS_OJ

  x.compare!
end

puts
puts "=" * 70
puts "BENCHMARK: Twitter-like Response (#{TWITTER_JSON.bytesize} bytes)"
puts "This tests the key caching optimization (repeated keys in array of objects)"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(TWITTER_JSON) }
  x.report("YYJson.load") { YYJson.load(TWITTER_JSON) }
  x.report("Oj.load") { Oj.load(TWITTER_JSON) } if HAS_OJ

  x.compare!
end

puts
puts "=" * 70
puts "BENCHMARK: With symbolize_names option"
puts "=" * 70
Benchmark.ips do |x|
  x.config(warmup: 1, time: 3)

  x.report("JSON.parse") { JSON.parse(TWITTER_JSON, symbolize_names: true) }
  x.report("YYJson.load") { YYJson.load(TWITTER_JSON, symbolize_names: true) }
  x.report("Oj.load") { Oj.load(TWITTER_JSON, symbol_keys: true) } if HAS_OJ

  x.compare!
end

puts
puts "Benchmark complete!"
