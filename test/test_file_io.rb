# frozen_string_literal: true

require_relative 'test_helper'

class TestFileIO < YYJsonTestCase
  def setup
    @temp_dir = create_temp_dir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.directory?(@temp_dir)
  end

  # load_file tests

  def test_load_file_with_valid_json
    file = create_temp_json_file('{"name": "John", "age": 30}')
    result = YYJson.load_file(file.path)
    assert_equal({ 'name' => 'John', 'age' => 30 }, result)
  ensure
    file&.unlink
  end

  def test_load_file_with_array
    file = create_temp_json_file('[1, 2, 3, 4, 5]')
    result = YYJson.load_file(file.path)
    assert_equal([1, 2, 3, 4, 5], result)
  ensure
    file&.unlink
  end

  def test_load_file_with_nested_structure
    json = '{"users": [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]}'
    file = create_temp_json_file(json)
    result = YYJson.load_file(file.path)
    assert_equal 2, result['users'].length
    assert_equal 'Alice', result['users'][0]['name']
  ensure
    file&.unlink
  end

  def test_load_file_with_symbolize_names
    file = create_temp_json_file('{"key": "value"}')
    result = YYJson.load_file(file.path, symbolize_names: true)
    assert_equal({ key: 'value' }, result)
  ensure
    file&.unlink
  end

  def test_load_file_with_freeze_option
    file = create_temp_json_file('{"frozen": "data"}')
    result = YYJson.load_file(file.path, freeze: true)
    assert result.frozen?
    assert result['frozen'].frozen?
  ensure
    file&.unlink
  end

  def test_load_file_nonexistent
    assert_raises(IOError) do
      YYJson.load_file('/nonexistent/path/file.json')
    end
  end

  def test_load_file_empty_file
    file = create_temp_json_file('')
    assert_raises(YYJson::ParseError) do
      YYJson.load_file(file.path)
    end
  ensure
    file&.unlink
  end

  def test_load_file_invalid_json
    file = create_temp_json_file('{"invalid": }')
    assert_raises(YYJson::ParseError) do
      YYJson.load_file(file.path)
    end
  ensure
    file&.unlink
  end

  def test_load_file_large_file
    large_data = generate_large_hash(1000)
    json = YYJson.dump(large_data)
    file = create_temp_json_file(json)
    result = YYJson.load_file(file.path)
    assert_equal 1000, result.keys.length
  ensure
    file&.unlink
  end

  def test_load_file_with_unicode
    file = create_temp_json_file('{"message": "Hello, \u4e16\u754c!"}')
    result = YYJson.load_file(file.path)
    assert_equal 'Hello, 世界!', result['message']
  ensure
    file&.unlink
  end

  def test_load_file_with_utf8_bom
    # UTF-8 BOM followed by JSON
    content = "\xEF\xBB\xBF{\"key\": \"value\"}"
    file = create_temp_json_file(content)
    # This may succeed or fail depending on implementation
    begin
      result = YYJson.load_file(file.path)
      assert_equal 'value', result['key']
    rescue YYJson::ParseError
      # BOM rejection is acceptable
      pass
    end
  ensure
    file&.unlink
  end

  # dump_file tests

  def test_dump_file_simple_object
    path = File.join(@temp_dir, 'output.json')
    data = { 'name' => 'John', 'age' => 30 }
    YYJson.dump_file(data, path)

    assert File.exist?(path)
    content = File.read(path)
    result = YYJson.load(content)
    assert_equal data, result
  end

  def test_dump_file_with_array
    path = File.join(@temp_dir, 'array.json')
    data = [1, 2, 3, 4, 5]
    YYJson.dump_file(data, path)

    content = File.read(path)
    result = YYJson.load(content)
    assert_equal data, result
  end

  def test_dump_file_overwrites_existing
    path = File.join(@temp_dir, 'overwrite.json')
    File.write(path, 'old content')

    YYJson.dump_file({ 'new' => 'data' }, path)

    content = File.read(path)
    result = YYJson.load(content)
    assert_equal({ 'new' => 'data' }, result)
  end

  def test_dump_file_with_pretty_option
    path = File.join(@temp_dir, 'pretty.json')
    data = { 'key' => 'value' }
    YYJson.dump_file(data, path, pretty: true)

    content = File.read(path)
    # Pretty printed JSON should contain newlines
    assert_includes content, "\n"
  end

  def test_dump_file_creates_subdirectories_fails
    path = File.join(@temp_dir, 'nonexistent', 'subdir', 'file.json')
    # Should fail because parent directory doesn't exist
    assert_raises(YYJson::GenerateError, IOError, Errno::ENOENT) do
      YYJson.dump_file({ 'data' => 'test' }, path)
    end
  end

  def test_dump_file_with_special_characters
    path = File.join(@temp_dir, 'special.json')
    data = {
      'quote' => 'He said "hello"',
      'backslash' => 'path\\to\\file',
      'newline' => "line1\nline2"
    }
    YYJson.dump_file(data, path)

    result = YYJson.load_file(path)
    assert_equal data, result
  end

  def test_dump_file_returns_nil_on_success
    path = File.join(@temp_dir, 'return.json')
    result = YYJson.dump_file({ 'test' => true }, path)
    # Should return nil or the number of bytes written
    assert_nil(result) || result.is_a?(Integer)
  end

  def test_dump_file_with_nested_structure
    path = File.join(@temp_dir, 'nested.json')
    data = {
      'users' => [
        { 'id' => 1, 'profile' => { 'name' => 'Alice', 'active' => true } },
        { 'id' => 2, 'profile' => { 'name' => 'Bob', 'active' => false } }
      ],
      'metadata' => { 'count' => 2 }
    }
    YYJson.dump_file(data, path)

    result = YYJson.load_file(path)
    assert_equal data, result
  end

  # Round-trip tests

  def test_file_round_trip
    path = File.join(@temp_dir, 'round_trip.json')
    original = sample_api_response
    YYJson.dump_file(original, path)
    loaded = YYJson.load_file(path)
    assert_equal original, loaded
  end

  def test_file_round_trip_with_unicode
    path = File.join(@temp_dir, 'unicode.json')
    original = {
      'chinese' => '你好世界',
      'japanese' => 'こんにちは',
      'emoji' => '😀🎉🚀',
      'arabic' => 'مرحبا'
    }
    YYJson.dump_file(original, path)
    loaded = YYJson.load_file(path)
    assert_equal original, loaded
  end
end
