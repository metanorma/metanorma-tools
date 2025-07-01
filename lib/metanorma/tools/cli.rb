# frozen_string_literal: true

require 'thor'

module Metanorma
  module Tools
    class Cli < Thor
      desc 'extract-images INPUT_XML', 'Extract images from Metanorma XML'
      option :output_dir, type: :string, aliases: '-o', desc: 'Output directory for extracted figures'
      option :prefix, type: :string, aliases: '-p', desc: 'Prefix for generated figure filenames'
      option :zip, type: :boolean, default: false, desc: 'Create a ZIP archive of extracted figures'
      option :verbose, type: :boolean, default: false, aliases: '-v', desc: 'Show detailed progress information'
      option :auto_prefix, type: :boolean, default: true, desc: 'Automatically generate prefix from document metadata'

      def extract_images(input_xml)
        extractor = FigureExtractor.new(options)
        extractor.extract(input_xml, options[:output_dir], options[:prefix])
      end
    end
  end
end
