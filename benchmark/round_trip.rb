#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/yyjson'
require_relative 'support/data_generator'
require_relative 'support/helpers'
require 'json'
require 'benchmark/ips'

begin
  require 'oj'
  HAS_OJ = true
rescue LoadError
  HAS_OJ = false
end

# Round-trip: data -> JSON -> data
data = BenchmarkDataGenerator.activerecord_array(count: 100)

BenchmarkHelpers.print_data_info("Round-trip Data", data)

puts "\n" + "=" * 60
puts "Round-trip Benchmark (dump + load)"
puts "=" * 60

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  x.report("YYJson") do
    json = YYJson.dump(data)
    YYJson.load(json)
  end

  x.report("JSON") do
    json = JSON.generate(data)
    JSON.parse(json)
  end

  if HAS_OJ
    x.report("Oj") do
      json = Oj.dump(data)
      Oj.load(json)
    end
  end

  x.compare!
end

puts "\n" + "=" * 60
puts "Benchmark Complete!"
puts "=" * 60
