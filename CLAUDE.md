# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

YYJson is a high-performance JSON parser and generator for Ruby, wrapping the ultra-fast [yyjson](https://github.com/ibireme/yyjson) C library. The project aims to be 2-5x faster than the standard JSON gem with 40-60% less memory usage while providing drop-in compatibility.

**Current Status**: MVP 01 (Core Parsing) complete. JSON parsing works; generation, Rails integration, and advanced modes are in progress.

## Build and Test Commands

### Building the Extension
```bash
# Compile the C extension (auto-downloads yyjson v0.10.0)
ruby ext/yyjson/extconf.rb
make -C ext/yyjson

# Or install the gem locally
gem build yyjson.gemspec
gem install yyjson-*.gem
```

### Running Tests
```bash
# Run all tests
ruby test/test_basic_parsing.rb

# Run with verbose output
ruby test/test_basic_parsing.rb -v

# Run a specific test
ruby test/test_basic_parsing.rb -n test_parse_simple_object
```

### Running Examples
```bash
# Basic usage example
ruby examples/basic_usage.rb
```

## Architecture

### C Extension Structure

The C extension is split into **small, focused modules** following SOLID principles:

1. **`yyjson_ext.c`** - Main entry point
   - Defines the `YYJson` module and public API methods
   - Delegates to specialized modules for actual work
   - Initializes symbol IDs and exception classes

2. **`parser.c/h`** - JSON parsing orchestration
   - `yyjson_parse_string()` - Parse from string
   - `yyjson_parse_file()` - Parse from file
   - `yyjson_extract_parse_options()` - Extract Ruby hash options to C struct
   - Wraps yyjson read functions and handles errors

3. **`value_builder.c/h`** - JSON → Ruby object conversion
   - `yyjson_build_ruby_object()` - Recursively converts yyjson values to Ruby objects
   - Handles all JSON types: null, bool, number, string, array, object
   - Implements performance optimizations: frozen strings, pre-allocated collections
   - Supports options: `symbolize_names`, `freeze`, etc.

4. **`object_dumper.c/h`** - Ruby object → JSON conversion
   - `yyjson_dump_ruby_object()` - Converts Ruby objects to yyjson mutable values
   - Handles type detection and recursive serialization
   - Planned: mode support (strict, compat, rails, object)

5. **`writer.c/h`** - JSON generation orchestration
   - `yyjson_write_string()` - Generate JSON string from Ruby object
   - `yyjson_write_file()` - Write JSON to file
   - `yyjson_extract_dump_options()` - Extract dump options
   - Wraps yyjson write functions

6. **`common.h`** - Shared definitions
   - Module/class/exception references
   - Symbol IDs for method names
   - Common macros (error raising, memory allocation, logging)
   - Enum for parsing modes (strict, compat, rails, object)
   - Utility functions (frozen string creation, falsey checks)

7. **`yyjson.c`** - Thin wrapper
   - Simply includes `vendor/yyjson-0.10.0/src/yyjson.c`
   - Required because yyjson is single-file library

### Key Design Patterns

**Small, Testable Modules**: Each `.c` file has a single responsibility and is typically 100-300 lines.

**Options Structs**: Parse/dump options extracted once from Ruby hashes into C structs (`yyjson_parse_options`, `yyjson_dump_options`), then passed by pointer to avoid repeated hash lookups.

**Performance-First**:
- **Frozen strings by default** - All parsed strings frozen for memory sharing
- **Pre-allocation** - Arrays use `rb_ary_new_capa()`, hashes use `rb_hash_new_capa()` (Ruby 3.2+)
- **Zero-copy** - Direct access to yyjson string buffers where possible
- **SIMD optimizations** - SSE4.2 enabled in extconf.rb for x86_64

**Error Handling**: yyjson errors converted to Ruby exceptions with position info and error codes.

### Ruby Library Structure

- **`lib/yyjson.rb`** - Entry point that requires the C extension
- **`lib/yyjson/version.rb`** - Version constant
- Exception classes defined in both Ruby and C for compatibility

### Vendor Library Management

**Auto-download pattern** (inspired by zsv-ruby):
- `extconf.rb` downloads yyjson v0.10.0 from GitHub if not present
- Extracts to `ext/yyjson/vendor/yyjson-0.10.0/`
- `vendor/` directory is gitignored
- Proper redirect handling for GitHub releases

### Mode System (Planned)

Inspired by Oj, YYJson will support multiple parsing/generation modes:
- `:strict` - Strict JSON spec compliance only
- `:compat` - JSON gem compatibility (default)
- `:rails` - Rails/ActiveSupport compatibility
- `:object` - Custom object serialization with `as_json()`

Currently only `:compat` mode is partially implemented.

## Development Workflow

### Adding New Features

1. Check `docs/mvp/` for implementation plans and checklists
2. Modify C code in `ext/yyjson/` following the modular structure
3. Keep source files small (aim for <300 lines per file)
4. Add tests to `test/` directory (use Minitest)
5. Update examples in `examples/` if adding user-facing features
6. Rebuild extension: `ruby ext/yyjson/extconf.rb && make -C ext/yyjson`

### C Extension Guidelines

- **Use `common.h` macros** for memory allocation (`YYJSON_ALLOC`, `YYJSON_FREE`) and errors (`RAISE_PARSE_ERROR`)
- **Freeze strings** using `rb_str_freeze()` or `yyjson_safe_str_new()`
- **Pre-allocate collections** using capacity hints from yyjson
- **Handle encoding** explicitly - all JSON strings are UTF-8
- **Check Ruby version features** with `#ifdef HAVE_RB_HASH_NEW_CAPA` etc.

### Testing Philosophy

- Use Minitest (simple, built into Ruby)
- Test files mirror source structure: `test/test_*.rb`
- Cover happy paths, edge cases, and error conditions
- Test options combinations
- Test file I/O with Tempfile

### Performance Optimization Strategy

1. **Measure first** - Use benchmarks before optimizing
2. **Pre-allocate** - Use size hints from yyjson for arrays/hashes
3. **Freeze strings** - Enable memory sharing, reduce GC pressure
4. **Minimize allocations** - Direct conversion, avoid intermediate objects
5. **Enable SIMD** - SSE4.2 flags in extconf.rb for x86_64

## Implementation Roadmap

See `docs/mvp/README.txt` for the full plan. Current progress:

- [x] MVP 01: Core Parsing - `YYJson.load()` working
- [ ] MVP 02: JSON Generation - `YYJson.dump()` implementation
- [ ] MVP 03: Rails Integration - `optimize_rails()` one-liner
- [ ] MVP 04: Parsing Modes - Multiple mode support
- [ ] MVP 05: Benchmarks - Performance testing suite
- [ ] MVP 06: Testing - Comprehensive test coverage
- [ ] MVP 07: Memory Optimization - Profiling and tuning
- [ ] MVP 08: Documentation - API docs and guides
- [ ] MVP 09: Build and Release - Gem publishing

## API Reference

### Parsing
```ruby
YYJson.load(json_string, opts = {})  # Parse JSON string
YYJson.parse(json_string, opts = {}) # Alias for load
YYJson.load_file(path, opts = {})    # Parse JSON file
```

### Generation (Planned)
```ruby
YYJson.dump(object, opts = {})       # Generate JSON string
YYJson.generate(object, opts = {})   # Alias for dump
YYJson.dump_file(object, path, opts = {})  # Write to file
```

### Options

**Parse Options**:
- `:symbolize_names` (bool) - Convert hash keys to symbols (default: false)
- `:freeze` (bool) - Freeze parsed objects (default: false)
- `:allow_nan` (bool) - Allow NaN/Infinity (default: true)
- `:allow_comments` (bool) - Allow C-style comments (default: true)
- `:max_nesting` (int) - Max nesting depth (default: 100)
- `:mode` (symbol) - Parsing mode (default: :compat)

**Dump Options** (Planned):
- `:mode` (symbol) - Generation mode (default: :compat)
- `:indent` (int/string) - Indentation for pretty printing
- `:pretty` (bool) - Pretty print (default: false)
- `:escape_slash` (bool) - Escape forward slashes (default: false)

## Important Files

- `ext/yyjson/extconf.rb` - Build configuration, yyjson download logic
- `ext/yyjson/common.h` - Shared definitions, macros, mode enum
- `ext/yyjson/yyjson_ext.c` - Main entry point, public API
- `ext/yyjson/value_builder.c` - Core parsing logic (JSON → Ruby)
- `ext/yyjson/object_dumper.c` - Core generation logic (Ruby → JSON)
- `docs/mvp/` - Implementation plans and todo lists
- `yyjson.gemspec` - Gem specification, dependencies

## Compiler Flags

Set in `ext/yyjson/extconf.rb`:
- `-std=c99` - C99 standard
- `-O3` - Aggressive optimization
- `-msse4.2` - SIMD on supported x86_64 CPUs
- `-Wall -Wextra` - Warning flags

## Dependencies

**Runtime**:
- Ruby >= 3.0.0
- bigdecimal >= 1.0

**Development**:
- rake >= 13.0
- rake-compiler >= 1.2
- minitest >= 5.0
- benchmark-ips >= 2.0

## Philosophy

**Fast and Lean**: Prioritize performance and memory efficiency. Profile before optimizing.

**SOLID Code**: Small, focused source files with single responsibilities. Easy to test and maintain.

**Compatibility**: Drop-in replacement for JSON gem and Oj where possible.

**Rails-Friendly**: One-line integration for Rails apps (planned).
