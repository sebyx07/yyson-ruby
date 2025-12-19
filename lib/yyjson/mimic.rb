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

# Ensure stdlib json is loaded first to get proper exception classes
require 'json' unless defined?(::JSON::ParserError)

# Monkey-patch JSON module to use YYJson
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

    def load(source, proc = nil, opts = {})
      # Handle both JSON.load(source, opts) and JSON.load(source, proc, opts)
      if proc.is_a?(Hash)
        opts = proc
        proc = nil
      end
      YYJson.load(source, opts)
    end

    def generate(obj, opts = {})
      YYJson.dump(obj, opts)
    end

    def dump(obj, anIO = nil, limit = nil, opts = {})
      # Handle the various argument patterns
      json = YYJson.dump(obj, opts)
      if anIO
        anIO.write(json)
        anIO
      else
        json
      end
    end

    def pretty_generate(obj, opts = {})
      YYJson.dump(obj, opts.merge(pretty: true))
    end

    # Restore original JSON gem methods
    def restore_json_gem!
      class << self
        alias_method :parse, :_original_parse if method_defined?(:_original_parse)
        alias_method :load, :_original_load if method_defined?(:_original_load)
        alias_method :generate, :_original_generate if method_defined?(:_original_generate)
        alias_method :dump, :_original_dump if method_defined?(:_original_dump)
        alias_method :pretty_generate, :_original_pretty_generate if method_defined?(:_original_pretty_generate)
      end
    end

    # Check if YYJson mimic is active
    def yyjson_mimic_active?
      true
    end
  end
end
