# YYJson API Reference

This document provides a complete reference for the YYJson Ruby API.

## Module Methods

### YYJson.load(source, opts = {})

Parse a JSON string into Ruby objects.

**Parameters:**
- `source` (String) - JSON string to parse
- `opts` (Hash) - Optional configuration

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:symbolize_names` | Boolean | `false` | Convert hash keys to symbols |
| `:freeze` | Boolean | `false` | Freeze all parsed objects |
| `:mode` | Symbol | `:compat` | Parsing mode (`:strict`, `:compat`, `:rails`) |
| `:allow_nan` | Boolean | `true` | Allow NaN/Infinity values |
| `:allow_comments` | Boolean | `true` | Allow C-style comments |
| `:max_nesting` | Integer | `100` | Maximum nesting depth |

**Returns:** Parsed Ruby object (Hash, Array, String, Numeric, Boolean, or nil)

**Raises:** `YYJson::ParseError` if JSON is invalid

**Examples:**
```ruby
# Basic parsing
data = YYJson.load('{"name": "John", "age": 30}')
# => {"name" => "John", "age" => 30}

# Symbolize keys
data = YYJson.load('{"name": "John"}', symbolize_names: true)
# => {name: "John"}

# Freeze result
data = YYJson.load('{"frozen": true}', freeze: true)
data.frozen?  # => true

# Strict mode (no NaN, Infinity, or comments)
data = YYJson.load('{"value": 123}', mode: :strict)
```

---

### YYJson.parse(source, opts = {})

Alias for `YYJson.load`. See above for documentation.

---

### YYJson.load_file(path, opts = {})

Parse JSON from a file.

**Parameters:**
- `path` (String) - Path to the JSON file
- `opts` (Hash) - Optional configuration (same as `load`)

**Returns:** Parsed Ruby object

**Raises:**
- `IOError` if file cannot be read
- `YYJson::ParseError` if JSON is invalid

**Examples:**
```ruby
# Load from file
config = YYJson.load_file('/path/to/config.json')

# Load with options
data = YYJson.load_file('data.json', symbolize_names: true)
```

---

### YYJson.dump(object, opts = {})

Generate JSON from a Ruby object.

**Parameters:**
- `object` (Object) - Ruby object to serialize
- `opts` (Hash) - Optional configuration

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:mode` | Symbol | `:compat` | Generation mode (`:strict`, `:compat`, `:rails`) |
| `:pretty` | Boolean | `false` | Pretty print with indentation |
| `:indent` | Integer/String | `2` | Indentation (spaces count or string) |
| `:escape_slash` | Boolean | `false` | Escape forward slashes (`/` → `\/`) |

**Supported Types:**
- `nil` → `null`
- `true`, `false` → `true`, `false`
- `Integer`, `Float` → JSON number
- `String`, `Symbol` → JSON string
- `Array` → JSON array
- `Hash` → JSON object
- `Time`, `Date`, `DateTime` → ISO8601 string
- `BigDecimal` → JSON number or string
- Objects with `as_json` method (in `:rails` mode)

**Returns:** JSON string (UTF-8 encoded)

**Raises:** `YYJson::GenerateError` if object cannot be serialized (e.g., circular reference)

**Examples:**
```ruby
# Basic generation
json = YYJson.dump({name: "John", age: 30})
# => '{"name":"John","age":30}'

# Pretty print
json = YYJson.dump({a: 1, b: 2}, pretty: true)
# => "{\n  \"a\": 1,\n  \"b\": 2\n}"

# Custom indent
json = YYJson.dump({a: 1}, pretty: true, indent: 4)
json = YYJson.dump({a: 1}, pretty: true, indent: "\t")

# Escape slashes
json = YYJson.dump({url: "http://example.com"}, escape_slash: true)
# => '{"url":"http:\\/\\/example.com"}'
```

---

### YYJson.generate(object, opts = {})

Alias for `YYJson.dump`. See above for documentation.

---

### YYJson.dump_file(object, path, opts = {})

Write JSON to a file.

**Parameters:**
- `object` (Object) - Ruby object to serialize
- `path` (String) - Path to output file
- `opts` (Hash) - Optional configuration (same as `dump`)

**Returns:** `nil`

**Raises:**
- `IOError` if file cannot be written
- `YYJson::GenerateError` if object cannot be serialized

**Examples:**
```ruby
# Write to file
YYJson.dump_file({config: "value"}, '/path/to/output.json')

# Write pretty-printed
YYJson.dump_file(data, 'output.json', pretty: true)
```

---

### YYJson.optimize_rails(opts = {})

Configure YYJson as the default JSON library for Rails applications.

**Parameters:**
- `opts` (Hash) - Optional configuration

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:mode` | Symbol | `:rails` | Default mode for all operations |

**Effects:**
- Replaces `JSON.parse` and `JSON.generate` with YYJson
- Sets `ActiveSupport.json_encoder` to YYJson
- Respects ActiveSupport global JSON settings

**Returns:** `true`

**Examples:**
```ruby
# In config/initializers/yyjson.rb
YYJson.optimize_rails

# With custom mode
YYJson.optimize_rails(mode: :compat)
```

---

## Parsing Modes

### :strict

Strict JSON specification compliance.

- Rejects `NaN`, `Infinity`, `-Infinity`
- Rejects C-style comments (`//` and `/* */`)
- Hash keys must be strings
- No custom object deserialization

### :compat (default)

Compatible with Ruby's standard JSON gem.

- Allows `NaN`, `Infinity` (configurable)
- Allows C-style comments (configurable)
- Supports `symbolize_names` option
- Compatible with JSON gem API

### :rails

Compatible with Rails/ActiveSupport.

- Always calls `as_json()` on objects before serialization
- Symbolizes names by default
- Handles Rails-specific types (TimeWithZone, etc.)
- Respects ActiveSupport global settings

---

## Exception Classes

### YYJson::Error

Base exception class for all YYJson errors.

```ruby
begin
  YYJson.load('invalid')
rescue YYJson::Error => e
  puts "YYJson error: #{e.message}"
end
```

### YYJson::ParseError

Raised when JSON parsing fails. Includes position information.

```ruby
begin
  YYJson.load('{"invalid": }')
rescue YYJson::ParseError => e
  puts e.message  # Includes line/column info
end
```

### YYJson::GenerateError

Raised when JSON generation fails (e.g., circular reference).

```ruby
circular = []
circular << circular

begin
  YYJson.dump(circular)
rescue YYJson::GenerateError => e
  puts "Cannot serialize: #{e.message}"
end
```

---

## JSON Gem Compatibility

To use YYJson as a drop-in replacement for the JSON gem:

```ruby
require 'yyjson/mimic'

# Now all JSON methods use YYJson
JSON.parse('{"key": "value"}')
JSON.generate({key: "value"})
JSON.pretty_generate({key: "value"})
JSON.load(json_string)
JSON.dump(object)
```

### Restoring Original JSON Gem

```ruby
# If JSON gem was loaded before mimic
JSON.restore_json_gem!
```

---

## Rails Integration

### YYJson::Rails::Encoder

Custom encoder for ActiveSupport JSON encoding.

```ruby
# Direct use (rarely needed)
json = YYJson::Rails::Encoder.encode({key: "value"})
```

### Configuration

```ruby
# Time precision for serialization
YYJson::Rails.time_precision = 3

# Use ISO8601 time format
YYJson::Rails.use_standard_json_time_format = true

# Escape HTML entities
YYJson::Rails.escape_html_entities_in_json = true

# Reset to defaults
YYJson::Rails.reset_config!
```

---

## Thread Safety

YYJson is thread-safe. Multiple threads can safely call parse and generate methods concurrently. Each operation allocates its own internal state and does not share mutable state between calls.

---

## Memory Management

YYJson uses several optimizations to minimize memory usage:

1. **Frozen Strings**: Parsed strings are frozen by default for hash keys
2. **String Interning**: Hash keys are interned for memory sharing
3. **Pre-allocation**: Arrays and hashes are pre-allocated based on JSON size hints
4. **Zero-copy**: Where possible, strings reference the original buffer

For maximum memory efficiency with read-only data:
```ruby
data = YYJson.load(json, freeze: true)
```
