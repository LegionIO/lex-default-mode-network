# frozen_string_literal: true

require_relative 'lib/legion/extensions/default_mode_network/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-default-mode-network'
  spec.version       = Legion::Extensions::DefaultModeNetwork::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Default Mode Network'
  spec.description   = 'Raichle (2001) Default Mode Network for brain-modeled agentic AI — ' \
                       'resting-state activation for self-referential processing, mind-wandering, ' \
                       'spontaneous planning, and social replay when the agent is not task-focused.'
  spec.homepage      = 'https://github.com/LegionIO/lex-default-mode-network'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-default-mode-network'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-default-mode-network'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-default-mode-network'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-default-mode-network/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-default-mode-network.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
