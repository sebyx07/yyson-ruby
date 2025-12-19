# YYJson Rails Integration Guide

This guide explains how to use YYJson with Ruby on Rails applications for improved JSON performance.

## Quick Start

Add YYJson to your Gemfile:

```ruby
gem 'yyjson'
```

Create an initializer at `config/initializers/yyjson.rb`:

```ruby
YYJson.optimize_rails
```

That's it! All JSON operations in your Rails app now use YYJson.

## What Gets Optimized

When you call `YYJson.optimize_rails`, the following changes are made:

1. **JSON Module**: `JSON.parse`, `JSON.generate`, `JSON.load`, `JSON.dump`, and `JSON.pretty_generate` all use YYJson
2. **ActiveSupport::JSON**: `ActiveSupport::JSON.encode` uses YYJson
3. **Controller Rendering**: `render json: @object` uses YYJson
4. **Model Serialization**: `@model.to_json` uses YYJson

## Configuration Options

### Basic Configuration

```ruby
# config/initializers/yyjson.rb

YYJson.optimize_rails(
  mode: :rails  # Default mode for all operations
)
```

### Advanced Configuration

```ruby
# config/initializers/yyjson.rb

# Set default mode
YYJson.optimize_rails(mode: :rails)

# Configure Rails-specific options
YYJson::Rails.time_precision = 3                      # Decimal places for time
YYJson::Rails.use_standard_json_time_format = true    # ISO8601 format
YYJson::Rails.escape_html_entities_in_json = true     # Escape < > & in JSON
```

## Controller Examples

### Rendering JSON

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    render json: @users  # Uses YYJson automatically
  end

  def show
    @user = User.find(params[:id])
    render json: @user, status: :ok
  end
end
```

### Parsing Request Body

```ruby
class ApiController < ApplicationController
  def create
    # Request body is automatically parsed with YYJson
    data = JSON.parse(request.body.read)

    # Or use params which are already parsed
    @record = Record.create!(record_params)
    render json: @record, status: :created
  end
end
```

## Model Serialization

### Using as_json

YYJson in Rails mode automatically calls `as_json` on objects:

```ruby
class User < ApplicationRecord
  def as_json(options = {})
    {
      id: id,
      name: name,
      email: email,
      created_at: created_at
    }
  end
end

# In controller
render json: @user  # Calls @user.as_json, then YYJson.dump
```

### Custom Serializers

```ruby
class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(options = {})
    {
      id: @user.id,
      name: @user.name,
      profile: {
        avatar_url: @user.avatar_url,
        bio: @user.bio
      }
    }
  end
end

# In controller
render json: UserSerializer.new(@user)
```

## ActiveSupport Types

YYJson handles Rails-specific types automatically:

### Time and Dates

```ruby
# ActiveSupport::TimeWithZone
time = Time.current
YYJson.dump({time: time}, mode: :rails)
# => '{"time":"2024-01-15T10:30:00.000Z"}'

# Date
date = Date.today
YYJson.dump({date: date}, mode: :rails)
# => '{"date":"2024-01-15"}'
```

### BigDecimal

```ruby
require 'bigdecimal'
price = BigDecimal('19.99')
YYJson.dump({price: price}, mode: :rails)
# => '{"price":"19.99"}'  # or as number depending on config
```

### ActionController::Parameters

```ruby
# In a controller
def create
  # params is ActionController::Parameters
  YYJson.dump(params.to_unsafe_h, mode: :rails)
end
```

## Performance Comparison

### Benchmark: Serializing ActiveRecord Collection

```ruby
# 1000 User records with associations
users = User.includes(:posts).limit(1000)

# Standard JSON gem
Benchmark.measure { 100.times { users.to_json } }
# => 4.2 seconds

# YYJson
YYJson.optimize_rails
Benchmark.measure { 100.times { users.to_json } }
# => 1.1 seconds (3.8x faster)
```

### Memory Usage

```ruby
# Standard JSON
ObjectSpace.memsize_of_all { JSON.parse(large_json) }
# => 12.5 MB

# YYJson
ObjectSpace.memsize_of_all { YYJson.load(large_json) }
# => 7.8 MB (38% less)
```

## Migration from Other Libraries

### From Standard JSON Gem

No changes needed! `YYJson.optimize_rails` makes JSON methods use YYJson.

### From Oj

```ruby
# Before (Oj)
Oj.optimize_rails

# After (YYJson)
YYJson.optimize_rails
```

Key differences from Oj:
- Similar API and mode system
- Different internal architecture (yyjson vs custom parser)
- YYJson may have different edge-case behavior

### From MultiJson

```ruby
# Before
MultiJson.use(:oj)

# After
YYJson.optimize_rails
# MultiJson is automatically configured if present
```

## Troubleshooting

### JSON Gem Conflicts

If you see conflicts with the JSON gem:

```ruby
# Ensure YYJson is loaded after JSON
# In config/initializers/yyjson.rb
require 'json'  # Load standard JSON first
require 'yyjson'
YYJson.optimize_rails
```

### ActiveSupport Not Detected

```
YYJson: ActiveSupport not detected. Using JSON gem mimic only.
```

This warning appears if you call `optimize_rails` before Rails is fully loaded. Move the call to an initializer.

### Encoding Issues

If you see encoding errors:

```ruby
# Ensure all strings are UTF-8
data = data.transform_values { |v| v.is_a?(String) ? v.encode('UTF-8') : v }
YYJson.dump(data)
```

### Custom Objects Not Serializing

Ensure your objects respond to `as_json`:

```ruby
class MyObject
  def as_json(options = {})
    { key: 'value' }
  end
end
```

## Testing

### RSpec Configuration

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  # YYJson is automatically used via optimize_rails

  # If you need to test JSON output
  config.include Module.new {
    def json_response
      YYJson.load(response.body)
    end
  }, type: :request
end
```

### Testing JSON Output

```ruby
RSpec.describe "Users API", type: :request do
  it "returns users as JSON" do
    get "/users"

    expect(response).to have_http_status(:ok)
    expect(json_response).to include(
      "users" => array_including(
        hash_including("id" => 1, "name" => "John")
      )
    )
  end
end
```

## Best Practices

1. **Call optimize_rails in an initializer**: This ensures it runs after Rails is loaded

2. **Use :rails mode**: It handles Rails-specific types correctly

3. **Implement as_json for custom objects**: YYJson calls as_json in Rails mode

4. **Profile before and after**: Verify performance improvements in your specific use case

5. **Test thoroughly**: Ensure JSON output matches expectations after migration

## API Reference

See [API_REFERENCE.md](API_REFERENCE.md) for complete API documentation.
