# frozen_string_literal: true

require_relative 'test_helper'

class TestParseErrors < YYJsonTestCase
  def test_empty_input
    error = assert_raises(YYJson::ParseError) do
      YYJson.load('')
    end
    assert_match(/empty|length|unexpected/i, error.message)
  end

  def test_whitespace_only
    error = assert_raises(YYJson::ParseError) do
      YYJson.load('   ')
    end
    assert_kind_of YYJson::ParseError, error
  end

  def test_unclosed_object
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"key": "value"')
    end
  end

  def test_unclosed_array
    assert_raises(YYJson::ParseError) do
      YYJson.load('[1, 2, 3')
    end
  end

  def test_trailing_comma_in_object
    # This may or may not be allowed depending on mode
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"a": 1,}', mode: :strict)
    end
  end

  def test_trailing_comma_in_array
    # This may or may not be allowed depending on mode
    assert_raises(YYJson::ParseError) do
      YYJson.load('[1, 2, 3,]', mode: :strict)
    end
  end

  def test_missing_colon_in_object
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"key" "value"}')
    end
  end

  def test_missing_comma_in_object
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"a": 1 "b": 2}')
    end
  end

  def test_missing_comma_in_array
    assert_raises(YYJson::ParseError) do
      YYJson.load('[1 2 3]')
    end
  end

  def test_invalid_escape_sequence
    # Invalid escape sequence \x is not valid JSON
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"text": "hello\\xworld"}')
    end
  end

  def test_unterminated_string
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"key": "unterminated}')
    end
  end

  def test_invalid_number_format
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"num": 01}')  # Leading zeros not allowed
    end
  end

  def test_invalid_literal
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"value": tru}')  # Misspelled true
    end
  end

  def test_invalid_unicode_escape
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"text": "\\uXYZZ"}')  # Invalid hex
    end
  end

  def test_unquoted_key
    assert_raises(YYJson::ParseError) do
      YYJson.load('{key: "value"}')
    end
  end

  def test_single_quoted_string
    assert_raises(YYJson::ParseError) do
      YYJson.load("{'key': 'value'}")
    end
  end

  def test_bare_value
    # Just a bare word is not valid JSON
    assert_raises(YYJson::ParseError) do
      YYJson.load('hello')
    end
  end

  def test_multiple_root_values
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"a": 1}{"b": 2}')
    end
  end

  def test_error_includes_position
    error = assert_raises(YYJson::ParseError) do
      YYJson.load('{"key": }')
    end
    # Error message should include position information
    assert_match(/\d|pos|line|column/i, error.message)
  end

  def test_null_byte_in_string
    # Embedded null bytes
    assert_raises(YYJson::ParseError) do
      YYJson.load("{\"key\": \"val\x00ue\"}")
    end
  end

  def test_control_characters_in_string
    # Unescaped control characters (except for valid escapes)
    assert_raises(YYJson::ParseError) do
      YYJson.load("{\"key\": \"line1\nline2\"}")  # Raw newline in string
    end
  end

  def test_nan_in_strict_mode
    assert_raises(YYJson::ParseError) do
      YYJson.load('NaN', mode: :strict)
    end
  end

  def test_infinity_in_strict_mode
    assert_raises(YYJson::ParseError) do
      YYJson.load('Infinity', mode: :strict)
    end
  end

  def test_negative_infinity_in_strict_mode
    assert_raises(YYJson::ParseError) do
      YYJson.load('-Infinity', mode: :strict)
    end
  end

  def test_comments_in_strict_mode
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"key": "value"} // comment', mode: :strict)
    end
  end

  def test_error_inheritance
    error = assert_raises(YYJson::ParseError) do
      YYJson.load('invalid')
    end
    assert_kind_of YYJson::Error, error
    assert_kind_of StandardError, error
  end
end
