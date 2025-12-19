$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'yyjson'

class TestBasicParsing < Minitest::Test
  def test_parse_empty_object
    result = YYJson.load('{}')
    assert_equal({}, result)
  end

  def test_parse_simple_object
    result = YYJson.load('{"name": "John", "age": 30}')
    assert_equal({"name" => "John", "age" => 30}, result)
  end

  def test_parse_empty_array
    result = YYJson.load('[]')
    assert_equal([], result)
  end

  def test_parse_simple_array
    result = YYJson.load('[1, 2, 3]')
    assert_equal([1, 2, 3], result)
  end

  def test_parse_nested_structure
    json = '{"users": [{"name": "Alice", "age": 25}, {"name": "Bob", "age": 30}]}'
    result = YYJson.load(json)
    expected = {
      "users" => [
        {"name" => "Alice", "age" => 25},
        {"name" => "Bob", "age" => 30}
      ]
    }
    assert_equal(expected, result)
  end

  def test_parse_numbers
    result = YYJson.load('{"int": 42, "float": 3.14, "negative": -10}')
    assert_equal(42, result["int"])
    assert_in_delta(3.14, result["float"], 0.001)
    assert_equal(-10, result["negative"])
  end

  def test_parse_null
    result = YYJson.load('{"value": null}')
    assert_nil(result["value"])
  end

  def test_parse_booleans
    result = YYJson.load('{"true": true, "false": false}')
    assert_equal(true, result["true"])
    assert_equal(false, result["false"])
  end

  def test_parse_unicode
    result = YYJson.load('{"greeting": "Hello, \u4e16\u754c!"}')
    assert_equal("Hello, 世界!", result["greeting"])
  end

  def test_symbolize_names
    result = YYJson.load('{"name": "John", "age": 30}', symbolize_names: true)
    assert_equal({name: "John", age: 30}, result)
  end

  def test_freeze_option
    result = YYJson.load('{"name": "John"}', freeze: true)
    assert(result.frozen?, "Result should be frozen")
    assert(result["name"].frozen?, "String values should be frozen")
  end

  def test_parse_with_comments
    json = <<~JSON
      {
        // This is a comment
        "name": "John",
        "age": 30 // Another comment
      }
    JSON
    result = YYJson.load(json)
    assert_equal({"name" => "John", "age" => 30}, result)
  end

  def test_parse_error
    assert_raises(YYJson::ParseError) do
      YYJson.load('{"invalid": }')
    end
  end

  def test_parse_alias
    result = YYJson.parse('{"test": true}')
    assert_equal({"test" => true}, result)
  end

  def test_load_file
    # Create a temporary JSON file
    require 'tempfile'
    file = Tempfile.new(['test', '.json'])
    file.write('{"loaded": "from file"}')
    file.close

    result = YYJson.load_file(file.path)
    assert_equal({"loaded" => "from file"}, result)
  ensure
    file.unlink if file
  end

  def test_load_file_not_found
    assert_raises(IOError) do
      YYJson.load_file('/nonexistent/file.json')
    end
  end
end
