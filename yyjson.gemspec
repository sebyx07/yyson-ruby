require_relative 'lib/yyjson/version'

Gem::Specification.new do |spec|
  spec.name = 'yyjson'
  spec.version = YYJson::VERSION
  spec.authors = ['sebi']
  spec.email = ['sebyx07.pro@gmail.com']

  spec.summary = 'Ultra-fast JSON parser and generator for Ruby, powered by yyjson'
  spec.description = <<~DESC
    YYJson is a high-performance JSON library for Ruby that wraps the blazing-fast
    yyjson C library (https://github.com/ibireme/yyjson). It provides a drop-in
    replacement for the standard JSON gem with significant performance improvements,
    Rails integration support, and smart memory allocation.
  DESC
  spec.homepage = 'https://github.com/sebyx07/yyson-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sebyx07/yyson-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/sebyx07/yyson-ruby/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/sebyx07/yyson-ruby/issues'
  spec.metadata['documentation_uri'] = 'https://github.com/sebyx07/yyson-ruby#readme'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released
  spec.files = Dir[
    'lib/**/*.rb',
    'ext/**/*.{c,h,rb}',
    'LICENSE*',
    'README.md',
    'CHANGELOG.md'
  ]

  spec.require_paths = ['lib']
  spec.extensions = ['ext/yyjson/extconf.rb']

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rake-compiler', '~> 1.2'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'benchmark-ips', '~> 2.0'

  # Runtime dependencies
  spec.add_dependency 'bigdecimal', '>= 1.0'
end
