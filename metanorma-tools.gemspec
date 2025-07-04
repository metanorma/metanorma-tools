# frozen_string_literal: true

require_relative 'lib/metanorma/tools/version'

all_files_in_git = Dir.chdir(File.expand_path(__dir__)) do
  `git ls-files -z`.split("\x0")
end

Gem::Specification.new do |spec|
  spec.name = 'metanorma-tools'
  spec.version = Metanorma::Tools::VERSION
  spec.authors = ['Ribose']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'Miscellaneous tools to work with Metanorma output.'
  spec.homepage = 'https://github.com/metanorma/metanorma-tools'
  spec.license = 'BSD-2-Clause'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"

  # Specify which files should be added to the gem when it is released.
  spec.files = all_files_in_git
               .reject { |f| f.match(%r{\A(?:test|features|bin|\.)/}) }

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'lutaml-model', '~> 0.7'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'rubyzip', '~> 2.0'
  spec.add_dependency 'thor'
  spec.add_dependency 'base64'
end
