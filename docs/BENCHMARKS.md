# YYJson Benchmarks

This document describes how to run benchmarks and interpret results.

## Running Benchmarks

```bash
# Install dependencies
bundle install

# Compile extension
rake compile

# Run all benchmarks
rake benchmark

# Run specific benchmarks
rake benchmark:parse      # Parsing benchmarks
rake benchmark:generate   # Generation benchmarks
rake benchmark:round_trip # Round-trip benchmarks
rake benchmark:memory     # Memory benchmarks
```

## Benchmark Philosophy

YYJson wraps the yyjson C library, which is one of the fastest JSON parsers available. However, performance in Ruby depends on many factors:

1. **Ruby version** - Ruby 3.4+ with YJIT provides excellent JSON gem performance
2. **Data structure** - Different libraries optimize for different data patterns
3. **Options used** - Features like `symbolize_names` or `freeze` affect performance
4. **Memory patterns** - String interning and pre-allocation strategies differ

## What YYJson Optimizes For

### Memory Efficiency

- **String interning** for hash keys - Repeated keys share memory
- **Pre-allocation** - Arrays and hashes pre-sized using yyjson hints
- **Frozen strings** - Hash keys are always frozen

### Feature Set

- **Comments support** - C-style comments in JSON (disabled in strict mode)
- **Multiple modes** - strict, compat, rails for different use cases
- **Rails integration** - One-liner setup with `optimize_rails`
- **Custom object serialization** - `as_json` method support

## Running Your Own Benchmarks

Create a benchmark for your specific use case:

```ruby
require 'benchmark/ips'
require 'json'
require 'yyjson'

# Your actual data
data = your_json_string

Benchmark.ips do |x|
  x.report("JSON") { JSON.parse(data) }
  x.report("YYJson") { YYJson.load(data) }
  x.compare!
end
```

## Memory Benchmarking

```ruby
require 'memory_profiler'
require 'yyjson'

report = MemoryProfiler.report do
  1000.times { YYJson.load('{"key": "value"}') }
end

report.pretty_print
```

## Notes

- Results vary between Ruby versions
- YJIT significantly improves JSON gem performance in Ruby 3.4+
- For production use, benchmark with your actual workloads
- Memory savings from string interning increase with repeated keys
