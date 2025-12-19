#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test script for Valgrind memory testing
# Run with: valgrind --leak-check=full ruby test/valgrind_test.rb

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require_relative '../lib/yyjson'
require_relative '../ext/yyjson/yyjson'

puts "YYJson Valgrind Memory Test"
puts "=" * 40

# Test 1: Basic parsing
puts "\n1. Testing basic parsing..."
100.times do
  YYJson.load('{"name": "John", "age": 30, "active": true}')
end
puts "   OK"

# Test 2: Parsing with options
puts "\n2. Testing parsing with options..."
100.times do
  YYJson.load('{"key": "value"}', symbolize_names: true)
  YYJson.load('{"frozen": true}', freeze: true)
end
puts "   OK"

# Test 3: Large JSON parsing
puts "\n3. Testing large JSON parsing..."
large_json = '{"items": [' + (1..1000).map { |i| "{\"id\": #{i}}" }.join(',') + ']}'
10.times do
  YYJson.load(large_json)
end
puts "   OK"

# Test 4: Nested structures
puts "\n4. Testing nested structures..."
nested = '{"a": {"b": {"c": {"d": {"e": "deep"}}}}}'
100.times do
  YYJson.load(nested)
end
puts "   OK"

# Test 5: JSON generation
puts "\n5. Testing JSON generation..."
100.times do
  YYJson.dump({ name: "John", age: 30, tags: %w[a b c] })
end
puts "   OK"

# Test 6: Pretty printing
puts "\n6. Testing pretty printing..."
50.times do
  YYJson.dump({ key: "value", nested: { inner: true } }, pretty: true)
end
puts "   OK"

# Test 7: Round-trip
puts "\n7. Testing round-trip..."
50.times do
  json = '{"users": [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]}'
  data = YYJson.load(json)
  YYJson.dump(data)
end
puts "   OK"

# Test 8: Error handling (parse errors)
puts "\n8. Testing error handling..."
50.times do
  begin
    YYJson.load('{"invalid": }')
  rescue YYJson::ParseError
    # Expected
  end
end
puts "   OK"

# Test 9: Unicode strings
puts "\n9. Testing unicode strings..."
50.times do
  YYJson.load('{"emoji": "🎉", "chinese": "你好", "mixed": "Hello 世界!"}')
  YYJson.dump({ emoji: "🚀", text: "こんにちは" })
end
puts "   OK"

# Test 10: File operations (using temp files)
puts "\n10. Testing file operations..."
require 'tempfile'
10.times do
  file = Tempfile.new(['test', '.json'])
  file.write('{"loaded": "from file"}')
  file.close
  YYJson.load_file(file.path)
  file.unlink
end
puts "   OK"

# Test 11: Dump to file
puts "\n11. Testing dump to file..."
require 'tempfile'
10.times do
  file = Tempfile.new(['output', '.json'])
  file.close
  YYJson.dump_file({ written: true }, file.path)
  file.unlink
end
puts "   OK"

# Force GC to clean up
puts "\n12. Running garbage collection..."
GC.start
GC.start
puts "   OK"

puts "\n" + "=" * 40
puts "All memory tests completed!"
puts "Check Valgrind output for memory leaks."
