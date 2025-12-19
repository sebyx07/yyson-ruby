# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'yyjson'

class TestModes < Minitest::Test
  def test_mode_strict_rejects_nan
    assert_raises(YYJson::ParseError) do
      YYJson.load('[NaN]', mode: :strict)
    end
  end

  def test_mode_strict_rejects_infinity
    assert_raises(YYJson::ParseError) do
      YYJson.load('[Infinity]', mode: :strict)
    end
  end

  def test_mode_strict_rejects_comments
    assert_raises(YYJson::ParseError) do
      YYJson.load('{ /* comment */ "key": 1 }', mode: :strict)
    end
  end

  def test_mode_strict_uses_string_keys
    result = YYJson.load('{"key": "value"}', mode: :strict)
    assert_instance_of String, result.keys.first
    assert_equal "key", result.keys.first
  end

  def test_mode_compat_allows_nan
    result = YYJson.load('[NaN]', mode: :compat)
    assert result.first.nan?
  end

  def test_mode_compat_allows_infinity
    result = YYJson.load('[Infinity]', mode: :compat)
    assert result.first.infinite?
  end

  def test_mode_compat_allows_comments
    result = YYJson.load('{ /* comment */ "key": 1 }', mode: :compat)
    assert_equal({"key" => 1}, result)
  end

  def test_mode_compat_uses_string_keys_by_default
    result = YYJson.load('{"key": "value"}', mode: :compat)
    assert_instance_of String, result.keys.first
  end

  def test_mode_rails_symbolizes_keys
    result = YYJson.load('{"key": "value"}', mode: :rails)
    assert_instance_of Symbol, result.keys.first
    assert_equal :key, result.keys.first
  end

  def test_mode_rails_allows_nan
    result = YYJson.load('[NaN]', mode: :rails)
    assert result.first.nan?
  end

  def test_mode_rails_allows_comments
    result = YYJson.load('{ /* comment */ "key": 1 }', mode: :rails)
    assert_equal({key: 1}, result)
  end

  def test_mode_strict_generation_escapes_slashes
    result = YYJson.dump({url: "http://example.com"}, mode: :strict)
    assert_includes result, "\\/"
  end

  def test_mode_rails_generation_escapes_html
    result = YYJson.dump({html: "<script>alert(1)</script>"}, mode: :rails)
    assert_includes result, "\\u003c"
    assert_includes result, "\\u003e"
  end

  def test_mode_can_be_overridden_with_explicit_options
    # Rails mode defaults to symbolize_names: true
    result = YYJson.load('{"key": "value"}', mode: :rails, symbolize_names: false)
    assert_instance_of String, result.keys.first
  end

  def test_default_mode_is_compat
    result_no_mode = YYJson.load('{"key": "value"}')
    result_compat = YYJson.load('{"key": "value"}', mode: :compat)
    assert_equal result_compat, result_no_mode
  end
end
