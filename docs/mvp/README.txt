YYJson-Ruby MVP Implementation Plan
====================================

This directory contains the comprehensive MVP (Minimum Viable Product) plan for
building yyjson-ruby: a high-performance JSON parser and generator for Ruby.

VISION
------
Create a drop-in replacement for Ruby's JSON gem and Oj that:
- Wraps the blazing-fast yyjson C library (https://github.com/ibireme/yyjson)
- Integrates seamlessly with Rails (like Oj's optimize_rails())
- Uses smart memory allocation for lower memory usage
- Provides multiple parsing modes (strict, compat, rails, object)
- Achieves 2-5x speedup over standard JSON gem

INSPIRATION
-----------
- zsv-ruby: C extension architecture, auto-download pattern, GC safety
- Oj: Rails integration, mode system, benchmarking, JSON gem compatibility

MVP DOCUMENTS
-------------
Each .txt file contains a focused set of [ ] checklist items for implementation.

01-core-parsing.txt           - JSON parsing with yyjson (HIGHEST PRIORITY)
02-json-generation.txt        - JSON generation from Ruby objects
03-rails-integration.txt      - Rails drop-in replacement & optimize_rails()
04-parsing-modes.txt          - Multiple modes (strict, compat, rails, object)
05-benchmarks.txt             - Performance benchmarking suite
06-testing.txt                - Comprehensive test coverage
07-memory-optimization.txt    - Smart allocation, frozen strings, pre-sizing
08-documentation.txt          - README, API docs, guides
09-build-and-release.txt      - Build system, CI, gem release
10-advanced-features.txt      - Post-MVP features (future roadmap)

RECOMMENDED IMPLEMENTATION ORDER
--------------------------------
1. Start with 01-core-parsing.txt
   - Get basic YYJson.load() working first
   - This proves the yyjson integration works

2. Then 02-json-generation.txt
   - Get basic YYJson.dump() working
   - Round-trip testing becomes possible

3. Then 06-testing.txt
   - Build test suite alongside features
   - Ensures quality from the start

4. Then 07-memory-optimization.txt
   - Add frozen strings, pre-allocation
   - This is what makes yyjson-ruby special

5. Then 03-rails-integration.txt
   - Implement optimize_rails()
   - JSON gem compatibility
   - Major value proposition for Rails users

6. Then 04-parsing-modes.txt
   - Add mode support
   - Differentiate from JSON gem

7. Then 05-benchmarks.txt
   - Prove performance claims
   - Marketing material

8. Then 08-documentation.txt
   - Make it usable by others
   - README, guides, examples

9. Then 09-build-and-release.txt
   - Polish for release
   - CI, gem building, publish

10. 10-advanced-features.txt is post-MVP
    - Add after core is stable
    - Streaming, schema validation, etc.

KEY PRINCIPLES
--------------
[ ] Performance First: Every design decision optimized for speed
[ ] Rails-Friendly: Make Rails integration trivial (one-liner)
[ ] Memory Efficient: Smart allocation, frozen strings, pre-sizing
[ ] Drop-in Replacement: Compatible with JSON gem and Oj APIs
[ ] Well Tested: Comprehensive test coverage from day one
[ ] Well Documented: Clear docs for users and AI assistants
[ ] Open Source: MIT license, public development

CRITICAL TECHNICAL DECISIONS
-----------------------------
- Use yyjson C library (fastest JSON parser benchmarked)
- Auto-download yyjson in extconf.rb (no system dependencies)
- Freeze all strings for memory sharing (Ruby optimization)
- Pre-allocate hashes/arrays with rb_hash_new_capa/rb_ary_new_capa
- Support multiple modes like Oj (not just one-size-fits-all)
- Implement optimize_rails() for Rails drop-in replacement
- Use benchmark-ips for accurate performance measurements
- Support Ruby 3.0+ (modern Ruby only)

SUCCESS METRICS
---------------
- 2-5x faster than JSON gem for parsing
- 2-4x faster than JSON gem for generation
- 40-60% less memory usage than JSON gem
- Competitive with Oj (within 20%)
- One-line Rails integration that works
- 100% test coverage of public API
- Clear, comprehensive documentation

GETTING STARTED
---------------
1. Read through 01-core-parsing.txt
2. Check off items as you implement them
3. Write tests for each feature
4. Run benchmarks to verify performance
5. Update documentation as you go

Each .txt file is designed to be self-contained with specific, actionable tasks.
Use these as your implementation roadmap!
