# Contributing to YYJson

Thank you for your interest in contributing to YYJson! This document provides guidelines and information for contributors.

## Reporting Bugs

Before creating a bug report, please check if the issue already exists. When creating a bug report, please include:

1. **Ruby version**: Output of `ruby -v`
2. **Platform**: OS and architecture (e.g., Ubuntu 22.04 x86_64)
3. **YYJson version**: Output of `YYJson::VERSION`
4. **Minimal reproduction**: The smallest code example that demonstrates the issue
5. **Expected behavior**: What you expected to happen
6. **Actual behavior**: What actually happened
7. **Stack trace**: If applicable, the full error message and backtrace

## Feature Requests

Feature requests are welcome! Please describe:

1. **Use case**: What problem are you trying to solve?
2. **Proposed solution**: How would you like it to work?
3. **Alternatives**: What alternatives have you considered?

## Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/sebyx07/yyjson-ruby.git
   cd yyjson-ruby
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Compile the C extension:
   ```bash
   rake compile
   ```

4. Run the tests:
   ```bash
   rake test
   ```

5. Run benchmarks:
   ```bash
   rake benchmark
   ```

## Making Changes

### Code Style

**Ruby Code:**
- Follow standard Ruby conventions
- Use 2 spaces for indentation
- Add `frozen_string_literal: true` to new files
- Keep lines under 100 characters

**C Code:**
- Use 4 spaces for indentation
- Follow the existing code style in `ext/yyjson/`
- Document functions with `/** ... */` comments
- Use `common.h` macros for memory allocation and error handling
- Keep source files small and focused (aim for <300 lines)

### Test Coverage

- Add tests for any new functionality
- Tests go in `test/test_*.rb` files
- Use Minitest (simple, built into Ruby)
- Cover happy paths, edge cases, and error conditions

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb in imperative mood ("Add", "Fix", "Update")
- Keep the first line under 72 characters
- Add details in the body if needed

Example:
```
Add freeze option for parsed arrays

When freeze: true is passed, arrays are now frozen in addition to
hashes and strings. This enables better memory sharing for
read-only data structures.

Fixes #123
```

### Pull Request Process

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Make your changes and commit them

3. Ensure all tests pass:
   ```bash
   rake test
   ```

4. Run benchmarks to check for performance regressions:
   ```bash
   rake benchmark
   ```

5. Push your branch and create a pull request

6. Fill out the PR template with:
   - Description of changes
   - Related issues
   - Testing performed
   - Performance impact (if applicable)

## Architecture Notes

### C Extension Structure

The C extension follows SOLID principles with small, focused modules:

- `yyjson_ext.c` - Entry point and public API
- `parser.c` - Parsing orchestration
- `value_builder.c` - JSON to Ruby conversion
- `object_dumper.c` - Ruby to JSON conversion
- `writer.c` - JSON output
- `common.h` - Shared definitions and macros

### Key Design Patterns

1. **Options Structs**: Parse/dump options are extracted once from Ruby hashes into C structs, then passed by pointer.

2. **Frozen Strings**: All parsed strings are frozen for memory sharing.

3. **Pre-allocation**: Arrays and hashes are pre-allocated using yyjson size hints.

4. **Error Handling**: yyjson errors are converted to Ruby exceptions with position info.

### Testing Strategy

- Unit tests in `test/test_*.rb`
- Edge cases in `test/test_edge_cases.rb`
- Performance tests in `test/test_performance.rb`
- Memory safety tests in `test/test_memory_safety.rb`

## License

By contributing to YYJson, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue for any questions about contributing!
