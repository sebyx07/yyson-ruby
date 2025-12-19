# frozen_string_literal: true

require_relative 'yyjson/version'

# Load the native extension
# Try multiple locations for different environments
extension_loaded = false

# 1. Try the installed gem location (lib/yyjson/)
begin
  require_relative 'yyjson/yyjson'
  extension_loaded = true
rescue LoadError
  # Not found in lib/yyjson/
end

# 2. Try the development build location (ext/yyjson/)
unless extension_loaded
  begin
    require_relative '../ext/yyjson/yyjson'
    extension_loaded = true
  rescue LoadError
    # Not found in ext/yyjson/
  end
end

unless extension_loaded
  raise LoadError, "Could not load yyjson native extension. " \
                   "Run 'rake compile' to build it."
end

module YYJson
  class Error < StandardError; end
  class ParseError < Error; end
  class GenerateError < Error; end
end
