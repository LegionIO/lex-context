# frozen_string_literal: true

require_relative 'lib/legion/extensions/context/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-context'
  spec.version       = Legion::Extensions::Context::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@iverson.io']

  spec.summary       = 'Contextual framing and situation model for LegionIO'
  spec.description   = 'Models situated conceptualization — maintains context frames that shape ' \
                       'perception, memory retrieval, and action selection. Tracks context switches ' \
                       'with measurable switch costs and familiarity-based discount.'
  spec.homepage      = 'https://github.com/LegionIO/lex-context'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.add_development_dependency 'legion-gaia'
end
