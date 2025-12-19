require 'mkmf'
require 'net/http'
require 'uri'
require 'fileutils'

# yyjson version to download
YYJSON_VERSION = '0.10.0'
YYJSON_URL = "https://github.com/ibireme/yyjson/archive/refs/tags/#{YYJSON_VERSION}.tar.gz"
VENDOR_DIR = File.expand_path('vendor', __dir__)
YYJSON_DIR = File.join(VENDOR_DIR, "yyjson-#{YYJSON_VERSION}")
YYJSON_SRC_DIR = File.join(YYJSON_DIR, 'src')

def download_yyjson
  puts "Downloading yyjson #{YYJSON_VERSION}..."

  FileUtils.mkdir_p(VENDOR_DIR)

  uri = URI.parse(YYJSON_URL)
  tar_path = File.join(VENDOR_DIR, "yyjson-#{YYJSON_VERSION}.tar.gz")

  # Download with redirects support
  max_redirects = 5
  redirects = 0

  loop do
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      case response
      when Net::HTTPRedirection
        redirects += 1
        if redirects > max_redirects
          raise "Too many redirects (#{redirects})"
        end
        location = response['location']
        puts "Following redirect to #{location}"
        uri = URI.parse(location)
        # Continue loop to follow redirect
      when Net::HTTPSuccess
        File.open(tar_path, 'wb') do |file|
          file.write(response.body)
        end
        # Success - extract and return
        puts "Extracting yyjson..."
        system("tar", "-xzf", tar_path, "-C", VENDOR_DIR) or raise "Failed to extract yyjson"
        File.delete(tar_path)
        puts "yyjson #{YYJSON_VERSION} downloaded successfully"
        return
      else
        raise "Failed to download yyjson: #{response.code} #{response.message}"
      end
    end
  end
end

# Download yyjson if not already present
unless File.directory?(YYJSON_DIR)
  download_yyjson
end

# Verify yyjson source exists
unless File.exist?(File.join(YYJSON_SRC_DIR, 'yyjson.h'))
  raise "yyjson source not found at #{YYJSON_SRC_DIR}"
end

# Add yyjson source directory to include path
$INCFLAGS << " -I#{YYJSON_SRC_DIR}"

# Compiler flags
$CFLAGS << ' -std=c99'
$CFLAGS << ' -O3' # Optimize for speed
$CFLAGS << ' -Wall -Wextra'

# Platform-specific optimizations
if RUBY_PLATFORM =~ /darwin/
  # macOS specific flags
  $CFLAGS << ' -mmacosx-version-min=10.13'
elsif RUBY_PLATFORM =~ /linux/
  # Linux specific flags
  $LIBS << ' -lm' # Math library
end

# SIMD optimizations (like Oj)
if RbConfig::CONFIG['host_cpu'] =~ /x86_64|amd64/
  $CFLAGS << ' -msse4.2' if system('grep -q sse4_2 /proc/cpuinfo 2>/dev/null')
end

# Feature detection for Ruby optimizations
have_func('rb_hash_new_capa', 'ruby.h')       # Hash pre-allocation (Ruby 3.2+)
have_func('rb_hash_bulk_insert', 'ruby.h')    # Bulk hash insert (Ruby 2.7+)
have_func('rb_gc_mark_movable', 'ruby.h')     # Compacting GC support
have_func('rb_enc_interned_str', 'ruby.h')    # Interned strings (Ruby 3.0+)
have_func('rb_interned_str', 'ruby.h')        # Interned strings alt
have_func('rb_utf8_str_new', 'ruby.h')        # Fast UTF-8 string (Ruby 2.7+)
have_func('rb_utf8_str_new_cstr', 'ruby.h')   # Fast UTF-8 C string

# Check for required headers
have_header('ruby.h') or raise 'ruby.h not found'

# Define macros for Ruby version
$defs.push("-DRUBY_VERSION_MAJOR=#{RUBY_VERSION.split('.')[0]}")
$defs.push("-DRUBY_VERSION_MINOR=#{RUBY_VERSION.split('.')[1]}")
$defs.push("-DRUBY_VERSION_PATCH=#{RUBY_VERSION.split('.')[2]}")

# Collect all C source files
# Note: yyjson.c is a wrapper that includes vendor/yyjson-0.10.0/src/yyjson.c
$srcs = Dir.glob(File.join(__dir__, '*.c'))

puts "Building yyjson extension with:"
puts "  Ruby version: #{RUBY_VERSION}"
puts "  yyjson version: #{YYJSON_VERSION}"
puts "  Compiler flags: #{$CFLAGS}"
puts "  Sources: #{$srcs.size} files"

# Create Makefile
create_makefile('yyjson/yyjson')
