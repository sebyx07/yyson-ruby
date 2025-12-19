# YYJson

Ultra-fast JSON parser and generator for Ruby, powered by [yyjson](https://github.com/ibireme/yyjson).

[![CI](https://github.com/sebyx07/yyson-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/sebyx07/yyson-ruby/actions)
[![Gem Version](https://badge.fury.io/rb/yyjson.svg)](https://badge.fury.io/rb/yyjson)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org)

## Features

- **Drop-in replacement** for the JSON gem
- **Rails integration** with one-liner setup (`YYJson.optimize_rails`)
- **Multiple parsing modes** (strict, compat, rails)
- **JSON5-like features** - Comments support, trailing commas
- **Smart memory allocation** with string interning for hash keys
- **Powered by yyjson** - One of the fastest JSON libraries in C
- **SIMD optimization** on supported x86_64 CPUs

## Installation

Add to your Gemfile:

```ruby
gem 'yyjson'
```

Or install directly:

```bash
gem install yyjson
```

## Quick Start

### Basic Usage

```ruby
require 'yyjson'

# Parse JSON
data = YYJson.load('{"name": "John", "age": 30}')
# => {"name" => "John", "age" => 30}

# Parse with symbol keys
data = YYJson.load('{"name": "John"}', symbolize_names: true)
# => {name: "John"}

# Generate JSON
json = YYJson.dump({name: "John", age: 30})
# => '{"name":"John","age":30}'

# Pretty print
json = YYJson.dump({name: "John"}, pretty: true)
# => "{\n  \"name\": \"John\"\n}"
```

### File Operations

```ruby
# Parse from file
data = YYJson.load_file('config.json')

# Write to file
YYJson.dump_file({config: "value"}, 'output.json')
```

### Rails Integration

```ruby
# In config/initializers/yyjson.rb
YYJson.optimize_rails
```

That's it! All JSON parsing and generation in your Rails app will now use YYJson.

### JSON Gem Compatibility

```ruby
require 'yyjson/mimic'

# Now JSON.parse and JSON.generate use YYJson
data = JSON.parse('{"key": "value"}')
json = JSON.generate({key: "value"})
```

## API Reference

### Parsing Methods

```ruby
YYJson.load(json_string, opts = {})    # Parse JSON string
YYJson.parse(json_string, opts = {})   # Alias for load
YYJson.load_file(path, opts = {})      # Parse JSON file
```

#### Parse Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:symbolize_names` | Boolean | `false` | Convert hash keys to symbols |
| `:freeze` | Boolean | `false` | Freeze all parsed objects |
| `:mode` | Symbol | `:compat` | Parsing mode (`:strict`, `:compat`, `:rails`) |
| `:allow_nan` | Boolean | `true` | Allow NaN/Infinity values |
| `:allow_comments` | Boolean | `true` | Allow C-style comments |
| `:max_nesting` | Integer | `100` | Maximum nesting depth |

### Generation Methods

```ruby
YYJson.dump(object, opts = {})               # Generate JSON string
YYJson.generate(object, opts = {})           # Alias for dump
YYJson.dump_file(object, path, opts = {})    # Write JSON to file
```

#### Dump Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:mode` | Symbol | `:compat` | Generation mode |
| `:pretty` | Boolean | `false` | Pretty print with indentation |
| `:indent` | Integer/String | `2` | Indentation (spaces or string) |
| `:escape_slash` | Boolean | `false` | Escape forward slashes |

### Parsing Modes

- **`:strict`** - JSON spec compliant only. Rejects NaN, Infinity, comments.
- **`:compat`** - JSON gem compatible (default). Allows NaN, Infinity, comments.
- **`:rails`** - Rails/ActiveSupport compatible. Calls `as_json()` on objects.

## Exception Classes

```ruby
YYJson::Error         # Base exception class
YYJson::ParseError    # Invalid JSON syntax
YYJson::GenerateError # Cannot generate JSON (e.g., circular reference)
```

## Benchmarks

Performance varies depending on Ruby version, data structure, and workload. Ruby 3.4's JSON gem is highly optimized with YJIT.

Run benchmarks yourself:

```bash
rake benchmark
```

Key characteristics:
- **Memory efficient** - String interning for hash keys reduces memory usage
- **Consistent performance** - Powered by yyjson's optimized C implementation
- **Feature-rich** - Supports comments, multiple modes, Rails integration

See [docs/BENCHMARKS.md](docs/BENCHMARKS.md) for detailed benchmark methodology.

## Requirements

- Ruby >= 3.0.0
- C compiler (GCC or Clang)
- x86_64 or ARM64 processor

## Development

```bash
# Clone the repository
git clone https://github.com/sebyx07/yyson-ruby.git
cd yyjson-ruby

# Install dependencies
bundle install

# Compile the extension
rake compile

# Run tests
rake test

# Run benchmarks
rake benchmark
```

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

## Project Structure

```
yyjson-ruby/
├── lib/yyjson/          # Ruby wrapper code
├── ext/yyjson/          # C extension source
│   ├── extconf.rb       # Build config (auto-downloads yyjson)
│   ├── yyjson_ext.c     # Main extension entry point
│   ├── parser.c         # JSON parsing logic
│   ├── value_builder.c  # JSON → Ruby conversion
│   ├── object_dumper.c  # Ruby → JSON conversion
│   ├── writer.c         # JSON output
│   ├── common.h         # Shared definitions
│   └── vendor/          # Downloaded yyjson C library (gitignored)
├── test/                # Test suite
├── benchmark/           # Performance benchmarks
├── docs/                # Documentation
├── examples/            # Usage examples
└── yyjson.gemspec       # Gem specification
```

## Contributing

Bug reports and pull requests are welcome on GitHub. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [yyjson](https://github.com/ibireme/yyjson) - The underlying C library by ibireme
- [Oj](https://github.com/ohler55/oj) - Inspiration for mode system and Rails integration
- [zsv-ruby](https://github.com/iamazeem/zsv-ruby) - Inspiration for C extension architecture
