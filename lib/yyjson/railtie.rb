# frozen_string_literal: true

require 'yyjson'
require 'rails/railtie'

module YYJson
  # Rails Railtie for automatic integration
  #
  # This Railtie automatically activates YYJson when used in a Rails application.
  # It can be configured via config.yyjson in your Rails configuration.
  #
  # Example configuration in config/application.rb:
  #   config.yyjson.mode = :rails
  #   config.yyjson.symbolize_names = true
  #
  class Railtie < ::Rails::Railtie
    config.yyjson = ActiveSupport::OrderedOptions.new

    # Set sensible defaults
    config.yyjson.mode = :rails
    config.yyjson.auto_optimize = true
    config.yyjson.symbolize_names = nil  # Let mode decide

    # Initialize YYJson after Rails initialization
    initializer 'yyjson.configure', after: :load_config_initializers do |app|
      # Only auto-optimize if enabled
      if app.config.yyjson.auto_optimize
        require 'yyjson/rails'

        options = {}
        options[:mode] = app.config.yyjson.mode if app.config.yyjson.mode
        options[:symbolize_names] = app.config.yyjson.symbolize_names if app.config.yyjson.symbolize_names

        YYJson.optimize_rails(options)

        # Log activation
        if ::Rails.logger
          ::Rails.logger.info "YYJson: Railtie activated with mode=#{options[:mode] || :rails}"
        end
      end
    end

    # Add generator for initializer
    generators do
      require 'generators/yyjson/install_generator'
    end
  end
end
