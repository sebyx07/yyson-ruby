# frozen_string_literal: true

require 'time' # For Time#iso8601

module BenchmarkDataGenerator
  # Generate a simple hash
  def self.simple_hash(size: 10)
    Hash[(1..size).map { |i| ["key_#{i}", "value_#{i}"] }]
  end

  # Generate a simple array
  def self.simple_array(size: 100)
    (1..size).to_a
  end

  # Generate nested structure
  def self.nested_hash(depth: 3, breadth: 5)
    return {value: rand(1000)} if depth <= 0

    Hash[(1..breadth).map do |i|
      ["key_#{i}", nested_hash(depth: depth - 1, breadth: breadth)]
    end]
  end

  # Generate ActiveRecord-style array of objects
  def self.activerecord_array(count: 100)
    (1..count).map do |i|
      {
        id: i,
        name: "User #{i}",
        email: "user#{i}@example.com",
        created_at: Time.now.iso8601,
        updated_at: Time.now.iso8601,
        active: i.even?,
        score: rand(100),
        metadata: {
          login_count: rand(1000),
          last_ip: "192.168.1.#{rand(255)}"
        }
      }
    end
  end

  # Generate API response-style JSON
  def self.api_response(items: 50)
    {
      status: "success",
      timestamp: Time.now.iso8601,
      data: {
        items: (1..items).map { |i|
          {
            id: i,
            title: "Item #{i}",
            description: "This is item number #{i}" * 3,
            tags: ["tag#{i}", "tag#{i+1}", "tag#{i+2}"],
            price: rand(100.0).round(2),
            available: i.odd?
          }
        },
        pagination: {
          page: 1,
          per_page: items,
          total: items * 10,
          total_pages: 10
        }
      }
    }
  end

  # Generate large JSON (1MB+)
  def self.large_json
    {
      users: activerecord_array(count: 1000),
      metadata: {
        generated_at: Time.now.iso8601,
        version: "1.0.0",
        stats: simple_hash(size: 100)
      }
    }
  end

  # Generate JSON string from data
  def self.to_json_string(data)
    require 'json'
    JSON.generate(data)
  end
end
