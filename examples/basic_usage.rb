#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/yyjson'

puts "YYJson Basic Usage Examples"
puts "=" * 50

# Example 1: Parse simple JSON
puts "\n1. Parse simple JSON:"
json = '{"name": "Alice", "age": 30, "active": true}'
result = YYJson.load(json)
p result
# => {"name"=>"Alice", "age"=>30, "active"=>true}

# Example 2: Parse arrays
puts "\n2. Parse arrays:"
json = '[1, 2, 3, 4, 5]'
result = YYJson.load(json)
p result
# => [1, 2, 3, 4, 5]

# Example 3: Parse nested structures
puts "\n3. Parse nested structures:"
json = <<~JSON
  {
    "users": [
      {"name": "Alice", "age": 25},
      {"name": "Bob", "age": 30}
    ],
    "total": 2
  }
JSON
result = YYJson.load(json)
p result

# Example 4: Symbolize names
puts "\n4. Symbolize hash keys:"
json = '{"name": "Charlie", "role": "admin"}'
result = YYJson.load(json, symbolize_names: true)
p result
# => {:name=>"Charlie", :role=>"admin"}

# Example 5: Freeze strings (memory optimization)
puts "\n5. Freeze strings for memory sharing:"
json = '{"greeting": "Hello, World!"}'
result = YYJson.load(json, freeze: true)
puts "Result frozen? #{result.frozen?}"
puts "String frozen? #{result['greeting'].frozen?}"

# Example 6: Parse with comments
puts "\n6. Parse JSON with comments:"
json = <<~JSON
  {
    // This is a comment
    "name": "David",
    "age": 35 // Another comment
  }
JSON
result = YYJson.load(json)
p result

# Example 7: Parse from file
puts "\n7. Parse from file:"
require 'tempfile'
file = Tempfile.new(['example', '.json'])
file.write('{"source": "file", "loaded": true}')
file.close
result = YYJson.load_file(file.path)
p result
file.unlink

# Example 8: Handle parse errors
puts "\n8. Handle parse errors:"
begin
  YYJson.load('{"invalid": }')
rescue YYJson::ParseError => e
  puts "Parse error caught: #{e.message}"
end

# Example 9: Parse special values
puts "\n9. Parse special numeric values:"
json = '{"infinity": Infinity, "negative_inf": -Infinity, "not_a_number": NaN}'
result = YYJson.load(json)
puts "Infinity: #{result['infinity']}"
puts "Negative Infinity: #{result['negative_inf']}"
puts "NaN: #{result['not_a_number']}"

puts "\n" + "=" * 50
puts "All examples completed successfully!"
