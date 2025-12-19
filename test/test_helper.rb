# frozen_string_literal: true

# Add lib to load path so 'require "yyjson"' works in tests
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'tempfile'
require 'fileutils'

# Load yyjson - this handles finding the extension automatically
require 'yyjson'

module TestHelpers
  # Create a temporary JSON file with the given content
  def create_temp_json_file(content, suffix: '.json')
    file = Tempfile.new(['test', suffix])
    file.write(content)
    file.close
    file
  end

  # Create a temporary directory for testing
  def create_temp_dir
    Dir.mktmpdir('yyjson_test')
  end

  # Generate a hash with specified number of keys
  def generate_large_hash(size)
    size.times.each_with_object({}) { |i, h| h["key_#{i}"] = "value_#{i}" }
  end

  # Generate an array with specified number of elements
  def generate_large_array(size)
    size.times.map { |i| i }
  end

  # Generate a deeply nested structure
  def generate_nested_structure(depth, type: :hash)
    if depth <= 0
      return type == :hash ? { 'value' => 'leaf' } : ['leaf']
    end

    if type == :hash
      { 'nested' => generate_nested_structure(depth - 1, type: type) }
    else
      [generate_nested_structure(depth - 1, type: type)]
    end
  end

  # Assert that two JSON structures are equivalent (ignoring key order)
  def assert_json_equal(expected, actual, msg = nil)
    expected_json = YYJson.dump(expected)
    actual_json = YYJson.dump(actual)

    # Parse and re-dump to normalize
    expected_normalized = YYJson.dump(YYJson.load(expected_json))
    actual_normalized = YYJson.dump(YYJson.load(actual_json))

    assert_equal expected_normalized, actual_normalized, msg
  end

  # Sample data generators
  def sample_user_data
    {
      'id' => 123,
      'name' => 'John Doe',
      'email' => 'john@example.com',
      'active' => true,
      'score' => 98.5,
      'tags' => %w[admin verified],
      'metadata' => nil,
      'created_at' => '2024-01-15T10:30:00Z'
    }
  end

  def sample_api_response
    {
      'status' => 'success',
      'data' => {
        'users' => (1..5).map do |i|
          {
            'id' => i,
            'name' => "User #{i}",
            'email' => "user#{i}@example.com"
          }
        end,
        'total' => 100,
        'page' => 1,
        'per_page' => 5
      },
      'meta' => {
        'request_id' => 'abc123',
        'timestamp' => '2024-01-15T10:30:00Z'
      }
    }
  end
end

# Base test class with helpers included
class YYJsonTestCase < Minitest::Test
  include TestHelpers
end
