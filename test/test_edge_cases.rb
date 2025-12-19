# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'yyjson'

class TestEdgeCases < Minitest::Test
  def test_empty_string_input
    assert_raises(YYJson::ParseError) do
      YYJson.load('')
    end
  end

  def test_empty_array
    result = YYJson.load('[]')
    assert_equal [], result
  end

  def test_empty_object
    result = YYJson.load('{}')
    assert_equal({}, result)
  end

  def test_empty_string_value
    result = YYJson.load('{"key": ""}')
    assert_equal({"key" => ""}, result)
  end

  def test_very_long_string
    long_string = "a" * 100_000
    data = {text: long_string}
    json = YYJson.dump(data)
    result = YYJson.load(json)
    assert_equal long_string, result["text"]
  end

  def test_very_large_array
    large_array = (1..10_000).to_a
    json = YYJson.dump(large_array)
    result = YYJson.load(json)
    assert_equal large_array, result
  end

  def test_deeply_nested_arrays
    nested = []
    current = nested
    20.times do
      new_array = []
      current << new_array
      current = new_array
    end

    json = YYJson.dump(nested)
    result = YYJson.load(json)
    assert_equal nested, result
  end

  def test_deeply_nested_hashes
    nested = {}
    current = nested
    20.times do |i|
      new_hash = {}
      current["level_#{i}"] = new_hash
      current = new_hash
    end
    current["final"] = "value"

    json = YYJson.dump(nested)
    result = YYJson.load(json)
    assert_equal nested, result
  end

  def test_nan_handling_by_mode
    # Compat mode allows NaN
    result = YYJson.load('[NaN]', mode: :compat)
    assert result.first.nan?

    # Strict mode rejects NaN
    assert_raises(YYJson::ParseError) do
      YYJson.load('[NaN]', mode: :strict)
    end
  end

  def test_infinity_handling_by_mode
    # Compat mode allows Infinity
    result = YYJson.load('[Infinity, -Infinity]', mode: :compat)
    assert_equal Float::INFINITY, result[0]
    assert_equal -Float::INFINITY, result[1]

    # Strict mode rejects Infinity
    assert_raises(YYJson::ParseError) do
      YYJson.load('[Infinity]', mode: :strict)
    end
  end

  def test_unicode_characters
    data = {"emoji" => "🎉", "chinese" => "你好", "arabic" => "مرحبا"}
    json = YYJson.dump(data)
    result = YYJson.load(json)
    assert_equal data, result
  end

  def test_special_characters_in_strings
    data = {
      "newline" => "line1\nline2",
      "tab" => "col1\tcol2",
      "quote" => 'He said "hello"',
      "backslash" => "path\\to\\file"
    }
    json = YYJson.dump(data)
    result = YYJson.load(json)
    assert_equal data, result
  end

  def test_numbers_at_boundaries
    data = {
      max_int: 2**53 - 1,
      min_int: -(2**53 - 1),
      small_float: 0.0000000001,
      large_float: 1e100,
      negative_zero: -0.0
    }
    json = YYJson.dump(data)
    result = YYJson.load(json)

    assert_equal data[:max_int], result["max_int"]
    assert_equal data[:min_int], result["min_int"]
    assert_in_delta data[:small_float], result["small_float"], 0.0000000001
  end

  def test_circular_reference_detection
    data = []
    data << data  # Circular reference

    assert_raises(YYJson::GenerateError) do
      YYJson.dump(data)
    end
  end

  def test_circular_hash_reference_detection
    data = {}
    data[:self] = data  # Circular reference

    assert_raises(YYJson::GenerateError) do
      YYJson.dump(data)
    end
  end

  def test_mixed_key_types_in_hash
    data = {"string_key" => 1, symbol_key: 2}
    json = YYJson.dump(data)
    result = YYJson.load(json)

    # Both should be converted to strings in JSON
    assert_includes result.keys, "string_key"
    assert_includes result.keys, "symbol_key"
  end

  def test_time_serialization
    time = Time.now
    data = {timestamp: time}
    json = YYJson.dump(data)
    result = YYJson.load(json)

    # Time should be serialized as a string (format may vary)
    assert_instance_of String, result["timestamp"]
    # Accept both ISO8601 (2024-01-15T10:30:00) and default (2024-01-15 10:30:00 +0000) formats
    assert_match(/\d{4}-\d{2}-\d{2}/, result["timestamp"])
  end
end
