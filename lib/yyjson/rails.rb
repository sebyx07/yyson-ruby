# frozen_string_literal: true

require 'yyjson'
require 'yyjson/mimic'

module YYJson
  module Rails
    # Rails-optimized JSON encoder
    #
    # This encoder is designed for use with ActiveSupport and Rails applications.
    # It automatically calls as_json() on objects and respects Rails JSON encoding settings.
    class Encoder
      # Encode a Ruby object to JSON
      #
      # @param value [Object] The object to encode
      # @param options [Hash] Encoding options
      # @return [String] JSON string
      def self.encode(value, options = {})
        # Set Rails mode by default
        opts = { mode: :rails }.merge(options)

        # Convert to as_json representation if needed
        # (YYJson C extension already does this in rails mode)
        YYJson.dump(value, opts)
      end
    end

    # Rails configuration accessor
    class << self
      attr_accessor :time_precision
      attr_accessor :use_standard_json_time_format
      attr_accessor :escape_html_entities_in_json

      def reset_config!
        @time_precision = nil
        @use_standard_json_time_format = true
        @escape_html_entities_in_json = true
      end
    end

    reset_config!
  end

  # One-liner Rails optimization
  #
  # This method replaces JSON and ActiveSupport::JSON with YYJson,
  # providing significant performance improvements for Rails applications.
  #
  # Usage:
  #   # In config/initializers/yyjson.rb
  #   YYJson.optimize_rails
  #
  # Options:
  #   :mode - JSON mode to use (:rails by default)
  #   :symbolize_names - Symbolize hash keys (true for Rails mode)
  #
  def self.optimize_rails(options = {})
    # Load JSON mimic to replace ::JSON
    require 'yyjson/mimic' unless defined?(::JSON)

    # Configure default mode
    @default_mode = options[:mode] || :rails

    # Try to integrate with ActiveSupport if available
    if defined?(::ActiveSupport)
      integrate_with_active_support(options)
    else
      # Not in Rails, just set up JSON mimic
      warn "YYJson: ActiveSupport not detected. Using JSON gem mimic only."
    end

    # Configure MultiJson if available (older Rails/gems)
    if defined?(::MultiJson)
      setup_multi_json
    end

    true
  end

  private

  # Integrate with ActiveSupport::JSON
  def self.integrate_with_active_support(options)
    return unless defined?(::ActiveSupport::JSON)

    # Set YYJson as the JSON encoder for ActiveSupport
    if defined?(::ActiveSupport::JSON::Encoding)
      ::ActiveSupport.json_encoder = YYJson::Rails::Encoder

      # Respect ActiveSupport global settings
      if ::ActiveSupport::JSON::Encoding.respond_to?(:use_standard_json_time_format)
        YYJson::Rails.use_standard_json_time_format =
          ::ActiveSupport::JSON::Encoding.use_standard_json_time_format
      end

      if ::ActiveSupport::JSON::Encoding.respond_to?(:time_precision)
        YYJson::Rails.time_precision =
          ::ActiveSupport::JSON::Encoding.time_precision
      end

      if ::ActiveSupport::JSON::Encoding.respond_to?(:escape_html_entities_in_json)
        YYJson::Rails.escape_html_entities_in_json =
          ::ActiveSupport::JSON::Encoding.escape_html_entities_in_json
      end
    end

    # Log activation
    if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
      ::Rails.logger.info "YYJson: Activated Rails optimization mode"
    end
  end

  # MultiJson adapter for YYJson
  module MultiJsonAdapter
    def self.load(string, options = {})
      opts = options.dup
      # Map MultiJson options to YYJson options
      opts[:symbolize_names] = opts.delete(:symbolize_keys) if opts.key?(:symbolize_keys)
      YYJson.load(string, opts)
    end

    def self.dump(object, options = {})
      opts = options.dup
      opts[:pretty] = true if opts.delete(:pretty_print)
      YYJson.dump(object, opts)
    end
  end

  # Setup MultiJson to use YYJson
  def self.setup_multi_json
    return unless defined?(::MultiJson)

    begin
      ::MultiJson.use(:yyjson)
    rescue ::MultiJson::AdapterError
      # Register the adapter
      if ::MultiJson.respond_to?(:register_adapter)
        ::MultiJson.register_adapter(:yyjson, MultiJsonAdapter)
        ::MultiJson.use(:yyjson)
      end
    end
  end
end
