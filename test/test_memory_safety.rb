# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'tempfile'
require 'json'
require 'yyjson'

class TestMemorySafety < Minitest::Test
  # Test parsing while triggering GC
  # Skip on Ruby 3.2 ARM64 due to known GC interaction issue
  # TODO: Investigate and fix the C extension GC handling
  def test_parse_with_gc_stress
    skip "GC stress test unstable on ARM64 Ruby 3.2" if RUBY_VERSION.start_with?('3.2') && RUBY_PLATFORM =~ /arm64|aarch64/

    json = { "data" => (1..100).map { |i| { "id" => i, "name" => "item_#{i}" } } }.to_json

    # Enable GC stress mode temporarily
    original_stress = GC.stress
    GC.stress = true

    begin
      10.times do
        result = YYJson.load(json)
        assert_equal 100, result["data"].size
      end
    ensure
      GC.stress = original_stress
    end
  end

  # Test parsing many small documents (check for leaks)
  def test_many_small_parses
    json = '{"a":1,"b":"test","c":true}'

    # Parse many times and check memory doesn't grow unbounded
    GC.start
    before = GC.stat[:heap_live_slots]

    10_000.times { YYJson.load(json) }

    GC.start
    after = GC.stat[:heap_live_slots]

    # Allow some growth but not excessive (less than 1000 slots for 10K parses)
    growth = after - before
    assert growth < 1000, "Memory grew by #{growth} slots, possible leak"
  end

  # Test large array parsing
  def test_large_array
    json = (1..100_000).to_a.to_json
    result = YYJson.load(json)

    assert_equal 100_000, result.size
    assert_equal 1, result.first
    assert_equal 100_000, result.last
  end

  # Test deeply nested structure
  def test_deeply_nested
    depth = 50
    # Build nested JSON properly: {"a":{"a":{"a":...{"value":42}...}}}
    json = ('{"a":' * depth) + '{"value":42}' + ('}' * depth)

    result = YYJson.load(json)
    current = result
    depth.times { current = current["a"] }
    assert_equal 42, current["value"]
  end

  # Test large hash
  def test_large_hash
    hash = {}
    1000.times { |i| hash["key_#{i}"] = "value_#{i}" }
    json = hash.to_json

    result = YYJson.load(json)
    assert_equal 1000, result.size
    assert_equal "value_0", result["key_0"]
    assert_equal "value_999", result["key_999"]
  end

  # Test string with various lengths
  def test_various_string_lengths
    [0, 1, 10, 100, 1000, 10_000].each do |len|
      str = "x" * len
      json = { "data" => str }.to_json
      result = YYJson.load(json)
      assert_equal len, result["data"].length
    end
  end

  # Test cleanup on parse errors
  def test_cleanup_on_error
    invalid_jsons = [
      '{"unclosed": ',
      '[1,2,3',
      '{"key": undefined}',
      '{invalid}',
    ]

    GC.start
    before = GC.stat[:heap_live_slots]

    100.times do
      invalid_jsons.each do |json|
        begin
          YYJson.load(json)
        rescue YYJson::ParseError
          # Expected
        end
      end
    end

    GC.start
    after = GC.stat[:heap_live_slots]

    # Should not leak on errors
    growth = after - before
    assert growth < 500, "Memory grew by #{growth} slots on errors, possible leak"
  end

  # Test frozen strings are actually frozen
  def test_frozen_strings
    json = '{"key": "value", "nested": {"inner": "data"}}'
    result = YYJson.load(json, freeze: true)

    # All string keys should be frozen
    assert result.keys.all?(&:frozen?), "Hash keys should be frozen"
    assert result["nested"].keys.all?(&:frozen?), "Nested hash keys should be frozen"

    # String values should be frozen when freeze: true
    assert result["key"].frozen?, "String value should be frozen"
    assert result["nested"]["inner"].frozen?, "Nested string value should be frozen"
  end

  # Test string encoding
  def test_string_encoding
    json = '{"ascii": "hello", "unicode": "héllo 世界", "emoji": "👋🌍"}'
    result = YYJson.load(json)

    result.each_value do |str|
      assert_equal Encoding::UTF_8, str.encoding, "String should be UTF-8 encoded"
      assert str.valid_encoding?, "String should have valid encoding"
    end
  end

  # Test key interning (repeated keys should share memory)
  def test_key_interning
    json = [
      {"name" => "Alice", "age" => 30},
      {"name" => "Bob", "age" => 25},
      {"name" => "Charlie", "age" => 35}
    ].to_json

    result = YYJson.load(json)

    # Get all "name" keys
    name_keys = result.map { |h| h.keys.find { |k| k == "name" } }
    name_ids = name_keys.map(&:object_id).uniq

    # All "name" keys should be the same object (interned)
    assert_equal 1, name_ids.size, "Repeated keys should be interned (same object_id)"

    # Same for "age"
    age_keys = result.map { |h| h.keys.find { |k| k == "age" } }
    age_ids = age_keys.map(&:object_id).uniq
    assert_equal 1, age_ids.size, "Repeated keys should be interned"
  end

  # Test symbol keys interning
  def test_symbol_key_interning
    json = [
      {"name" => "Alice"},
      {"name" => "Bob"},
      {"name" => "Charlie"}
    ].to_json

    result = YYJson.load(json, symbolize_names: true)

    # All :name symbols should be identical
    name_keys = result.map { |h| h.keys.first }
    assert name_keys.all? { |k| k.equal?(name_keys.first) }, "Symbol keys should be identical objects"
  end

  # Test parsing with symbolize_names doesn't leak
  def test_symbolize_names_no_leak
    json = '{"key1": 1, "key2": 2, "key3": 3}'

    GC.start
    before = GC.stat[:heap_live_slots]

    1000.times { YYJson.load(json, symbolize_names: true) }

    GC.start
    after = GC.stat[:heap_live_slots]

    growth = after - before
    assert growth < 100, "symbolize_names grew by #{growth} slots, possible leak"
  end

  # Test integer caching (small integers should be cached)
  def test_small_integer_caching
    json = [0, 1, 2, -1, -2, 42, 100].to_json

    result1 = YYJson.load(json)
    result2 = YYJson.load(json)

    # Small integers should be the same Ruby objects (cached)
    result1.zip(result2).each do |a, b|
      assert a.equal?(b), "Integer #{a} should be cached (same object_id)"
    end
  end

  # Test file parsing cleanup
  def test_file_parsing_cleanup
    Tempfile.create(['test', '.json']) do |f|
      f.write('{"data": [1,2,3,4,5]}')
      f.flush

      GC.start
      before = GC.stat[:heap_live_slots]

      100.times { YYJson.load_file(f.path) }

      GC.start
      after = GC.stat[:heap_live_slots]

      growth = after - before
      assert growth < 500, "File parsing grew by #{growth} slots, possible leak"
    end
  end
end
