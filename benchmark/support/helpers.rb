# frozen_string_literal: true

require 'benchmark/ips'

module BenchmarkHelpers
  def self.compare_libraries(name, data, &block)
    puts "\n" + "=" * 60
    puts "Benchmark: #{name}"
    puts "=" * 60

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      yield x, data

      x.compare!
    end
  end

  def self.format_size(bytes)
    if bytes < 1024
      "#{bytes}B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(2)}KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(2)}MB"
    end
  end

  def self.print_data_info(name, data)
    json_str = JSON.generate(data)
    puts "Data: #{name}"
    puts "Size: #{format_size(json_str.bytesize)}"
    puts "Type: #{data.class}"
    if data.is_a?(Array)
      puts "Elements: #{data.size}"
    elsif data.is_a?(Hash)
      puts "Keys: #{data.keys.size}"
    end
    puts ""
  end
end
