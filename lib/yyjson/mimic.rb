# frozen_string_literal: true

require 'yyjson'

# JSON gem compatibility layer
#
# This file provides drop-in compatibility with the standard JSON gem by
# monkey-patching the ::JSON module to use YYJson under the hood.
#
# Usage:
#   require 'yyjson/mimic'
#
# After requiring, all JSON.parse and JSON.generate calls will use YYJson.

unless defined?(::JSON)
  # Define JSON module if it doesn't exist
  module JSON
    # Parse JSON string
    #
    # @param source [String] JSON string to parse
    # @param opts [Hash] Options hash
    # @option opts [Boolean] :symbolize_names Convert hash keys to symbols
    # @option opts [Boolean] :allow_nan Allow NaN/Infinity values
    # @option opts [Integer] :max_nesting Maximum nesting depth
    # @return [Object] Parsed Ruby object
    def self.parse(source, opts = {})
      YYJson.load(source, opts)
    end

    # Load JSON string (alias for parse)
    #
    # @param source [String] JSON string to parse
    # @param opts [Hash] Options hash
    # @return [Object] Parsed Ruby object
    def self.load(source, opts = {})
      YYJson.load(source, opts)
    end

    # Generate JSON string from Ruby object
    #
    # @param obj [Object] Ruby object to convert to JSON
    # @param opts [Hash] Options hash
    # @option opts [Boolean] :pretty Pretty print
    # @option opts [String, Integer] :indent Indentation (spaces or count)
    # @return [String] JSON string
    def self.generate(obj, opts = {})
      YYJson.dump(obj, opts)
    end

    # Dump JSON string (alias for generate)
    #
    # @param obj [Object] Ruby object to convert to JSON
    # @param opts [Hash] Options hash
    # @return [String] JSON string
    def self.dump(obj, opts = {})
      YYJson.dump(obj, opts)
    end

    # Pretty-print JSON
    #
    # @param obj [Object] Ruby object to convert to JSON
    # @param opts [Hash] Options hash
    # @return [String] Pretty-printed JSON string
    def self.pretty_generate(obj, opts = {})
      YYJson.dump(obj, opts.merge(pretty: true))
    end

    # JSON parse error
    class ParserError < StandardError; end

    # JSON generation error
    class GeneratorError < StandardError; end
  end

  # Map YYJson exceptions to JSON exceptions
  class YYJson::ParseError
    # Make YYJson::ParseError behave like JSON::ParserError
    def self.===(other)
      other.is_a?(YYJson::ParseError) || other.is_a?(JSON::ParserError)
    end
  end

  class YYJson::GenerateError
    # Make YYJson::GenerateError behave like JSON::GeneratorError
    def self.===(other)
      other.is_a?(YYJson::GenerateError) || other.is_a?(JSON::GeneratorError)
    end
  end
else
  # JSON module already exists, monkey-patch it
  module JSON
    class << self
      # Save original methods
      alias_method :_original_parse, :parse if method_defined?(:parse)
      alias_method :_original_load, :load if method_defined?(:load)
      alias_method :_original_generate, :generate if method_defined?(:generate)
      alias_method :_original_dump, :dump if method_defined?(:dump)
      alias_method :_original_pretty_generate, :pretty_generate if method_defined?(:pretty_generate)

      # Override with YYJson implementations
      def parse(source, opts = {})
        YYJson.load(source, opts)
      end

      def load(source, opts = {})
        YYJson.load(source, opts)
      end

      def generate(obj, opts = {})
        YYJson.dump(obj, opts)
      end

      def dump(obj, opts = {})
        YYJson.dump(obj, opts)
      end

      def pretty_generate(obj, opts = {})
        YYJson.dump(obj, opts.merge(pretty: true))
      end

      # Restore original JSON gem methods
      def restore_json_gem!
        if method_defined?(:_original_parse)
          alias_method :parse, :_original_parse
          alias_method :load, :_original_load
          alias_method :generate, :_original_generate
          alias_method :dump, :_original_dump
          alias_method :pretty_generate, :_original_pretty_generate
        end
      end

      # Check if YYJson mimic is active
      def yyjson_mimic_active?
        method(:parse).source_location&.first&.include?('yyjson/mimic')
      end
    end
  end
end
