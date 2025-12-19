# frozen_string_literal: true

require_relative 'yyjson/version'

begin
  # Try to require the extension from the build directory
  RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "../ext/yyjson/yyjson"
rescue LoadError
  # Fall back to the installed version
  require 'yyjson/yyjson'
end

module YYJson
  class Error < StandardError; end
  class ParseError < Error; end
  class GenerateError < Error; end
end
