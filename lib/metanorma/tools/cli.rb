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

      desc 'extract-images INPUT_XML', 'Extract embedded figures from Metanorma presentation XML files'
      long_desc <<~DESC
        Extract embedded figures from Metanorma presentation XML files with ISO DRG compliance features.

        This tool automatically extracts document metadata, generates ISO DRG compliant filenames,
        and supports both SVG and PNG figure formats with optional ZIP packaging.

        For detailed usage examples and options, see: docs/figure-extraction.adoc
      DESC
      option :output_dir, type: :string, aliases: '-o', desc: 'Output directory for extracted figures'
      option :prefix, type: :string, aliases: '-p', desc: 'Prefix for generated figure filenames'
      option :zip, type: :boolean, default: false, desc: 'Create a ZIP archive of extracted figures'
      option :verbose, type: :boolean, default: false, aliases: '-v', desc: 'Show detailed progress information'
      option :retain_original_filenames, type: :boolean, default: false, desc: 'For ISO documents, retain original filenames in generated names'

      def extract_images(input_xml)
        extractor = FigureExtractor.new(options)
        extractor.extract(input_xml, options[:output_dir], options[:prefix])
      end

      # Placeholder for future comment management functionality
      # Will integrate metanorma/commenter gem functionality
      desc 'comment SUBCOMMAND', 'Manage ISO comment sheets (planned)'
      subcommand 'comment', CommentCli if defined?(CommentCli)

      # Placeholder for future ISO document fetching functionality
      desc 'fetch-iso DOCUMENT_ID', 'Fetch ISO documents from OBP (planned)'
      def fetch_iso(document_id)
        puts "ISO document fetching functionality is planned for future release."
        puts "This will fetch ISO documents from the OBP into Metanorma format."
        puts "Document ID: #{document_id}"
      end

      # Help command that shows the expanded purpose
      desc 'help [COMMAND]', 'Show help for metanorma-tools commands'
      def help(command = nil)
        if command.nil?
          puts <<~HELP
            Metanorma Tools - Standards Editing Lifecycle Support
            =====================================================

            Metanorma Tools supports the lifecycle of standards editing for various flavors
            to facilitate pre and post-compilation of Metanorma documents.

            Available tools:
            • Figure extraction - Extract embedded figures from Metanorma presentation XML files
            • Comment management - Manage ISO comment sheets (planned)
            • ISO document fetching - Fetch documents from OBP (planned)

            For detailed documentation, see the docs/ directory:
            • docs/figure-extraction.adoc - Figure extraction guide
            • docs/iso-drg-filename-guidance.adoc - ISO DRG compliance guidance

            Commands:
          HELP
        end
        super
      end
    end
  end
end
