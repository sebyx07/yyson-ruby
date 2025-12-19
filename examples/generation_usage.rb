#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/yyjson'

puts "YYJson Generation Examples"
puts "=" * 50

# Example 1: Dump simple values
puts "\n1. Dump simple values:"
puts "nil: #{YYJson.dump(nil)}"
puts "true: #{YYJson.dump(true)}"
puts "false: #{YYJson.dump(false)}"
puts "42: #{YYJson.dump(42)}"
puts "3.14: #{YYJson.dump(3.14)}"
puts '"hello": ' + YYJson.dump("hello")

# Example 2: Dump collections
puts "\n2. Dump collections:"
puts "Array: #{YYJson.dump([1, 2, 3])}"
puts "Hash: #{YYJson.dump({name: "Alice", age: 30})}"

# Example 3: Dump complex structures
puts "\n3. Dump complex structure:"
obj = {
  users: [
    {name: "Alice", age: 25, active: true},
    {name: "Bob", age: 30, active: false}
  ],
  metadata: {
    version: "1.0",
    tags: ["ruby", "json"]
  }
}
json = YYJson.dump(obj)
puts json

# Example 4: Pretty printing
puts "\n4. Pretty printing:"
json_pretty = YYJson.dump(obj, pretty: true)
puts json_pretty

# Example 5: Custom indent
puts "\n5. Custom indent (4 spaces):"
json_indent = YYJson.dump({a: 1, b: {c: 2}}, indent: 4)
puts json_indent

# Example 6: Round-trip (dump + load)
puts "\n6. Round-trip conversion:"
original = {
  name: "Test",
  numbers: [1, 2, 3],
  nested: {
    bool: true,
    null: nil
  }
}
puts "Original:"
p original

json = YYJson.dump(original)
puts "\nJSON:"
puts json

parsed = YYJson.load(json)
puts "\nParsed back:"
p parsed

puts "\nAre they equal (normalized)?"
puts parsed == {
  "name" => "Test",
  "numbers" => [1, 2, 3],
  "nested" => {
    "bool" => true,
    "null" => nil
  }
}

# Example 7: File I/O
puts "\n7. File I/O (dump_file + load_file):"
require 'tempfile'
file = Tempfile.new(['example', '.json'])

data = {written: "to file", timestamp: Time.now.to_i}
YYJson.dump_file(data, file.path, pretty: true)

puts "Wrote to: #{file.path}"
puts "File contents:"
puts File.read(file.path)

loaded = YYJson.load_file(file.path)
puts "\nLoaded back:"
p loaded

file.unlink

# Example 8: Special values
puts "\n8. Special numeric values:"
puts "Infinity: #{YYJson.dump(Float::INFINITY)}"
puts "-Infinity: #{YYJson.dump(-Float::INFINITY)}"
puts "NaN: #{YYJson.dump(Float::NAN)}"

# Example 9: Escape slashes
puts "\n9. Escape slashes option:"
url_obj = {url: "https://example.com/path"}
puts "Normal: #{YYJson.dump(url_obj)}"
puts "Escaped: #{YYJson.dump(url_obj, escape_slash: true)}"

# Example 10: Symbol keys
puts "\n10. Symbol keys (converted to strings):"
with_symbols = {first_name: "John", last_name: "Doe", age: 30}
puts YYJson.dump(with_symbols)

puts "\n" + "=" * 50
puts "All examples completed successfully!"
