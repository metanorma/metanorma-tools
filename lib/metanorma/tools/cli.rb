# frozen_string_literal: true

require 'thor'

module Metanorma
  module Tools
    class Cli < Thor
      def self.exit_on_failure?
        true
      end

      map %w[--version -v] => :__version

      desc '--version, -v', 'Print the version'
      def __version
        puts Metanorma::Tools::VERSION
      end
      desc 'extract-images INPUT_XML', 'Extract images from Metanorma XML'
      option :output_dir, type: :string, aliases: '-o', desc: 'Output directory for extracted figures'
      option :prefix, type: :string, aliases: '-p', desc: 'Prefix for generated figure filenames'
      option :zip, type: :boolean, default: false, desc: 'Create a ZIP archive of extracted figures'
      option :verbose, type: :boolean, default: false, aliases: '-v', desc: 'Show detailed progress information'
      option :retain_original_filenames, type: :boolean, default: false, desc: 'For ISO documents, retain original filenames in generated names'

      def extract_images(input_xml)
        extractor = FigureExtractor.new(options)
        extractor.extract(input_xml, options[:output_dir], options[:prefix])
      end
    end
  end
end
