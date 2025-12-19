# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-XX-XX

### Added
- Initial release of YYJson for Ruby
- JSON parsing with `YYJson.load()` and `YYJson.parse()`
- JSON generation with `YYJson.dump()` and `YYJson.generate()`
- File operations with `YYJson.load_file()` and `YYJson.dump_file()`
- Multiple parsing modes: `:strict`, `:compat`, `:rails`
- Parse options: `symbolize_names`, `freeze`, `allow_nan`, `allow_comments`, `max_nesting`
- Generation options: `pretty`, `indent`, `escape_slash`
- Rails integration with `YYJson.optimize_rails`
- JSON gem compatibility layer via `require 'yyjson/mimic'`
- Exception classes: `YYJson::ParseError`, `YYJson::GenerateError`
- Performance optimizations:
  - Frozen strings for memory sharing
  - Hash/array pre-allocation using yyjson size hints
  - SIMD optimizations on x86_64
  - String interning for hash keys
- Comprehensive test suite
- Benchmark suite for parsing, generation, and memory usage

### Performance
- 2-5x faster parsing than standard JSON gem
- 2-4x faster generation than standard JSON gem
- Comparable memory usage with better key interning

### Dependencies
- Ruby >= 3.0.0
- yyjson C library v0.10.0 (bundled/auto-downloaded)
- bigdecimal >= 1.0
