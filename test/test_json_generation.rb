require 'minitest/autorun'
require_relative '../lib/yyjson'
require_relative '../ext/yyjson/yyjson'

class TestJSONGeneration < Minitest::Test
  def test_dump_nil
    result = YYJson.dump(nil)
    assert_equal("null", result)
  end

  def test_dump_true
    result = YYJson.dump(true)
    assert_equal("true", result)
  end

  def test_dump_false
    result = YYJson.dump(false)
    assert_equal("false", result)
  end

  def test_dump_integer
    result = YYJson.dump(42)
    assert_equal("42", result)
  end

  def test_dump_negative_integer
    result = YYJson.dump(-100)
    assert_equal("-100", result)
  end

  def test_dump_float
    result = YYJson.dump(3.14)
    assert_match(/3\.14/, result)
  end

  def test_dump_string
    result = YYJson.dump("hello")
    assert_equal('"hello"', result)
  end

  def test_dump_string_with_escapes
    result = YYJson.dump("hello\nworld\t!")
    assert_equal('"hello\\nworld\\t!"', result)
  end

  def test_dump_string_with_quotes
    result = YYJson.dump('say "hello"')
    assert_equal('"say \\"hello\\""', result)
  end

  def test_dump_unicode
    result = YYJson.dump("世界")
    assert_equal('"世界"', result)
  end

  def test_dump_symbol
    result = YYJson.dump(:hello)
    assert_equal('"hello"', result)
  end

  def test_dump_empty_array
    result = YYJson.dump([])
    assert_equal("[]", result)
  end

  def test_dump_simple_array
    result = YYJson.dump([1, 2, 3])
    assert_equal("[1,2,3]", result)
  end

  def test_dump_mixed_array
    result = YYJson.dump([1, "two", true, nil])
    assert_equal('[1,"two",true,null]', result)
  end

  def test_dump_nested_array
    result = YYJson.dump([1, [2, 3], 4])
    assert_equal("[1,[2,3],4]", result)
  end

  def test_dump_empty_hash
    result = YYJson.dump({})
    assert_equal("{}", result)
  end

  def test_dump_simple_hash
    result = YYJson.dump({name: "Alice", age: 30})
    # Order might vary, so parse and compare
    parsed = YYJson.load(result)
    assert_equal({"name" => "Alice", "age" => 30}, parsed)
  end

  def test_dump_nested_hash
    obj = {
      user: {
        name: "Bob",
        settings: {
          theme: "dark"
        }
      }
    }
    result = YYJson.dump(obj)
    parsed = YYJson.load(result)
    expected = {
      "user" => {
        "name" => "Bob",
        "settings" => {
          "theme" => "dark"
        }
      }
    }
    assert_equal(expected, parsed)
  end

  def test_dump_hash_with_string_keys
    result = YYJson.dump({"name" => "Charlie", "age" => 25})
    parsed = YYJson.load(result)
    assert_equal({"name" => "Charlie", "age" => 25}, parsed)
  end

  def test_dump_complex_structure
    obj = {
      users: [
        {name: "Alice", age: 25, active: true},
        {name: "Bob", age: 30, active: false}
      ],
      total: 2,
      metadata: {
        version: "1.0",
        tags: ["ruby", "json"]
      }
    }
    result = YYJson.dump(obj)
    parsed = YYJson.load(result)

    assert_equal(2, parsed["users"].length)
    assert_equal("Alice", parsed["users"][0]["name"])
    assert_equal(2, parsed["total"])
    assert_equal("1.0", parsed["metadata"]["version"])
  end

  def test_dump_pretty
    obj = {name: "Alice", age: 30}
    result = YYJson.dump(obj, pretty: true)

    assert_match(/\n/, result)  # Should have newlines
    assert_match(/\s{2}"/, result)  # Should have indentation
  end

  def test_dump_with_indent
    obj = {name: "Bob"}
    result = YYJson.dump(obj, indent: 2)

    assert_match(/\n/, result)
    assert_match(/\s{2}"/, result)
  end

  def test_dump_escape_slash
    obj = {url: "http://example.com/path"}
    result = YYJson.dump(obj, escape_slash: true)

    assert_match(/http:\\\/\\\//, result)
  end

  def test_dump_infinity
    result = YYJson.dump(Float::INFINITY)
    assert_equal("Infinity", result)
  end

  def test_dump_negative_infinity
    result = YYJson.dump(-Float::INFINITY)
    assert_equal("-Infinity", result)
  end

  def test_dump_nan
    result = YYJson.dump(Float::NAN)
    assert_equal("NaN", result)
  end

  def test_dump_strict_mode_rejects_nan
    assert_raises(YYJson::GenerateError) do
      YYJson.dump(Float::NAN, mode: :strict)
    end
  end

  def test_dump_file
    require 'tempfile'
    file = Tempfile.new(['test', '.json'])

    obj = {written: "to file", success: true}
    YYJson.dump_file(obj, file.path)

    # Read back and verify
    result = YYJson.load_file(file.path)
    assert_equal({"written" => "to file", "success" => true}, result)
  ensure
    file.unlink if file
  end

  def test_generate_alias
    result = YYJson.generate({test: true})
    parsed = YYJson.load(result)
    assert_equal({"test" => true}, parsed)
  end

  def test_round_trip
    obj = {
      name: "Test",
      numbers: [1, 2, 3],
      nested: {
        bool: true,
        null: nil
      }
    }

    json = YYJson.dump(obj)
    parsed = YYJson.load(json)

    assert_equal("Test", parsed["name"])
    assert_equal([1, 2, 3], parsed["numbers"])
    assert_equal(true, parsed["nested"]["bool"])
    assert_nil(parsed["nested"]["null"])
  end

  def test_circular_reference_detection
    a = []
    a << a  # Circular reference

    assert_raises(YYJson::GenerateError) do
      YYJson.dump(a)
    end
  end

  def test_deep_nesting
    obj = {a: {b: {c: {d: {e: {f: {g: "deep"}}}}}}}
    result = YYJson.dump(obj)
    parsed = YYJson.load(result)

    assert_equal("deep", parsed["a"]["b"]["c"]["d"]["e"]["f"]["g"])
  end

  def test_dump_custom_object_with_to_s
    obj = Object.new
    def obj.to_s
      "custom object"
    end

    result = YYJson.dump(obj)
    assert_equal('"custom object"', result)
  end
end
