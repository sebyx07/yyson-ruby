# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require_relative '../lib/yyjson'
require_relative '../ext/yyjson/yyjson'
require 'yyjson/mimic'

class TestCompat < Minitest::Test
  def test_json_parse_works_after_mimic
    result = JSON.parse('{"key": "value"}')
    assert_equal({"key" => "value"}, result)
  end

  def test_json_generate_works_after_mimic
    result = JSON.generate({key: "value"})
    assert_equal('{"key":"value"}', result)
  end

  def test_json_load_works_after_mimic
    result = JSON.load('{"key": "value"}')
    assert_equal({"key" => "value"}, result)
  end

  def test_json_dump_works_after_mimic
    result = JSON.dump({key: "value"})
    assert_equal('{"key":"value"}', result)
  end

  def test_json_pretty_generate_works
    result = JSON.pretty_generate({key: "value", nested: {deep: "data"}})
    assert_match(/\n/, result) # Has newlines
    assert_match(/"key"/, result)
  end

  def test_json_parse_with_symbolize_names
    result = JSON.parse('{"key": "value"}', symbolize_names: true)
    assert_equal({key: "value"}, result)
  end

  def test_json_module_defined
    assert defined?(JSON)
    assert JSON.respond_to?(:parse)
    assert JSON.respond_to?(:generate)
  end

  def test_json_parser_error_defined
    assert defined?(JSON::ParserError)
  end

  def test_json_generator_error_defined
    assert defined?(JSON::GeneratorError)
  end

  def test_invalid_json_raises_parser_error
    assert_raises(YYJson::ParseError) do
      JSON.parse('invalid json')
    end
  end

  def test_output_matches_json_gem_for_basic_types
    data = {
      "string" => "hello",
      "number" => 42,
      "float" => 3.14,
      "bool" => true,
      "null" => nil,
      "array" => [1, 2, 3],
      "hash" => {"nested" => "value"}
    }

    yyjson_output = YYJson.dump(data)
    parsed_back = YYJson.load(yyjson_output)

    assert_equal data, parsed_back
  end
end
