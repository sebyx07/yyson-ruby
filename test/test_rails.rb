# frozen_string_literal: true

require_relative 'test_helper'

# Add lib to load path for mimic/rails requires
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Load mimic and rails after yyjson is loaded by test_helper
require 'yyjson/mimic'
require 'yyjson/rails'

class TestRailsIntegration < YYJsonTestCase
  # Test JSON gem mimic functionality
  # (these tests work without ActiveSupport/Rails)

  def test_json_parse_after_mimic
    result = ::JSON.parse('{"key": "value"}')
    assert_equal({ 'key' => 'value' }, result)
  end

  def test_json_generate_after_mimic
    result = ::JSON.generate({ key: 'value' })
    parsed = YYJson.load(result)
    assert_equal 'value', parsed['key']
  end

  def test_json_load_after_mimic
    result = ::JSON.load('{"numbers": [1, 2, 3]}')
    assert_equal [1, 2, 3], result['numbers']
  end

  def test_json_dump_after_mimic
    data = { 'name' => 'John', 'age' => 30 }
    result = ::JSON.dump(data)
    parsed = YYJson.load(result)
    assert_equal data, parsed
  end

  def test_json_pretty_generate_after_mimic
    data = { 'key' => 'value' }
    result = ::JSON.pretty_generate(data)
    # Pretty output should have newlines
    assert_includes result, "\n"
  end

  def test_json_parse_with_symbolize_names
    result = ::JSON.parse('{"key": "value"}', symbolize_names: true)
    assert_equal({ key: 'value' }, result)
  end

  # Test YYJson::Rails::Encoder

  def test_encoder_encode_simple_object
    result = YYJson::Rails::Encoder.encode({ 'key' => 'value' })
    parsed = YYJson.load(result)
    assert_equal({ 'key' => 'value' }, parsed)
  end

  def test_encoder_encode_with_options
    result = YYJson::Rails::Encoder.encode({ 'key' => 'value' }, pretty: true)
    assert_includes result, "\n"
  end

  def test_encoder_sets_rails_mode
    # Encoder should use rails mode by default
    time = Time.now
    result = YYJson::Rails::Encoder.encode({ 'time' => time })
    parsed = YYJson.load(result)
    # Time should be serialized as ISO8601 string
    assert_instance_of String, parsed['time']
  end

  # Test optimize_rails method (without actual Rails)

  def test_optimize_rails_returns_true
    result = YYJson.optimize_rails
    assert_equal true, result
  end

  def test_optimize_rails_with_mode_option
    result = YYJson.optimize_rails(mode: :compat)
    assert_equal true, result
  end

  # Test Rails configuration accessors

  def test_rails_time_precision_accessor
    YYJson::Rails.time_precision = 3
    assert_equal 3, YYJson::Rails.time_precision
  ensure
    YYJson::Rails.reset_config!
  end

  def test_rails_use_standard_json_time_format_accessor
    YYJson::Rails.use_standard_json_time_format = false
    assert_equal false, YYJson::Rails.use_standard_json_time_format
  ensure
    YYJson::Rails.reset_config!
  end

  def test_rails_escape_html_entities_accessor
    YYJson::Rails.escape_html_entities_in_json = false
    assert_equal false, YYJson::Rails.escape_html_entities_in_json
  ensure
    YYJson::Rails.reset_config!
  end

  def test_rails_reset_config
    YYJson::Rails.time_precision = 99
    YYJson::Rails.reset_config!
    assert_nil YYJson::Rails.time_precision
    assert_equal true, YYJson::Rails.use_standard_json_time_format
    assert_equal true, YYJson::Rails.escape_html_entities_in_json
  end

  # Test as_json support

  def test_object_with_as_json
    klass = Class.new do
      def initialize(value)
        @value = value
      end

      def as_json(options = {})
        { 'custom' => @value }
      end
    end

    obj = klass.new('test_value')
    result = YYJson.dump(obj, mode: :rails)
    parsed = YYJson.load(result)
    assert_equal({ 'custom' => 'test_value' }, parsed)
  end

  def test_hash_as_json_passthrough
    data = { 'key' => 'value' }
    result = YYJson.dump(data, mode: :rails)
    parsed = YYJson.load(result)
    assert_equal data, parsed
  end

  def test_array_as_json_passthrough
    data = [1, 2, 3]
    result = YYJson.dump(data, mode: :rails)
    parsed = YYJson.load(result)
    assert_equal data, parsed
  end

  # Test serialization of common Ruby types in Rails mode

  def test_time_serialization_rails_mode
    time = Time.now
    result = YYJson.dump({ 'time' => time }, mode: :rails)
    parsed = YYJson.load(result)
    assert_match(/\d{4}-\d{2}-\d{2}T/, parsed['time'])
  end

  def test_date_serialization_rails_mode
    require 'date'
    date = Date.today
    result = YYJson.dump({ 'date' => date }, mode: :rails)
    parsed = YYJson.load(result)
    assert_match(/\d{4}-\d{2}-\d{2}/, parsed['date'])
  end

  def test_bigdecimal_serialization_rails_mode
    require 'bigdecimal'
    bd = BigDecimal('123.456')
    result = YYJson.dump({ 'decimal' => bd }, mode: :rails)
    parsed = YYJson.load(result)
    # BigDecimal might be serialized as string (various formats) or number
    value = parsed['decimal']
    if value.is_a?(String)
      # Could be "123.456", "0.123456e3", "123.456E0", etc.
      assert_in_delta 123.456, BigDecimal(value).to_f, 0.001, "Expected BigDecimal representation: #{value}"
    else
      assert_in_delta 123.456, value.to_f, 0.001
    end
  end

  def test_symbol_serialization_rails_mode
    result = YYJson.dump({ key: :value }, mode: :rails)
    parsed = YYJson.load(result)
    assert_equal 'value', parsed['key']
  end

  # Test nested as_json calls

  def test_nested_objects_with_as_json
    inner_class = Class.new do
      def as_json(options = {})
        { 'inner' => 'value' }
      end
    end

    outer_class = Class.new do
      def initialize(inner)
        @inner = inner
      end

      def as_json(options = {})
        { 'nested' => @inner.as_json(options) }
      end
    end

    inner = inner_class.new
    outer = outer_class.new(inner)
    result = YYJson.dump(outer, mode: :rails)
    parsed = YYJson.load(result)
    assert_equal({ 'nested' => { 'inner' => 'value' } }, parsed)
  end

  # Test error handling

  def test_parse_error_compatibility
    assert_raises(YYJson::ParseError) do
      ::JSON.parse('invalid json')
    end
  end

  def test_generation_error_for_circular_reference
    data = []
    data << data

    assert_raises(YYJson::GenerateError) do
      ::JSON.generate(data)
    end
  end
end
