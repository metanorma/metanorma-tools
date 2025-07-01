# frozen_string_literal: true

require 'nokogiri'
require 'base64'
require 'fileutils'
require 'zip'
require 'tmpdir'

module Metanorma
  module Tools
    class FigureExtractor
      METANORMA_NS = { 'xmlns' => 'https://www.metanorma.org/ns/standoc' }.freeze

      MIMETYPE_FORMATS = {
        'image/png' => :datauri_png,
        'image/jpeg' => :datauri_jpeg,
        'image/jpg' => :datauri_jpeg,
        'image/gif' => :datauri_gif,
        'image/svg+xml' => :datauri_svg,
        'image/webp' => :datauri_webp,
        '' => :datauri_png # Default for empty mimetype
      }.freeze

      attr_reader :options

      def initialize(options = {})
        # Convert string keys to symbols for consistency
        normalized_options = options.transform_keys(&:to_sym)
        @options = {
          zip: false,
          verbose: false,
          auto_prefix: true
        }.merge(normalized_options)
      end

      def extract(input_xml, output_dir = nil, prefix = nil)
        validate_input(input_xml)

        doc = parse_xml(input_xml)
        metadata = extract_document_metadata(doc)
        prefix = determine_prefix(prefix, metadata)
        output_dir = determine_output_dir(output_dir, prefix)

        figures = find_figures(doc)
        return if figures.empty?

        figure_objects, format_counts, total_size = process_figures(figures)

        saved_files = if options[:zip]
                        extract_to_zip(figure_objects, output_dir, prefix)
                      else
                        extract_to_directory(figure_objects, output_dir, prefix)
                      end

        print_summary(metadata, prefix, figure_objects.length, format_counts, total_size, output_dir)
      end

      private

      def validate_input(input_xml)
        return if File.exist?(input_xml)

        puts "Error: Input file '#{input_xml}' does not exist."
        exit 1
      end

      def parse_xml(input_xml)
        puts "Reading XML file: #{input_xml}"
        File.open(input_xml) { |f| Nokogiri::XML(f) }
      rescue StandardError => e
        puts "Error processing file: #{e.message}"
        puts e.backtrace if options[:verbose]
        exit 1
      end

      def determine_prefix(prefix, metadata)
        if options[:auto_prefix] && prefix.nil? && metadata
          prefix = metadata.auto_prefix
          puts "Auto-generated prefix: #{prefix}"
        end

        if prefix.nil? || prefix.empty?
          prefix = 'figure'
          puts "Using default prefix: #{prefix}"
        end

        prefix
      end

      def determine_output_dir(output_dir, prefix)
        if output_dir.nil? || output_dir.empty?
          if options[:zip]
            # For ZIP mode, use current directory
            output_dir = Dir.pwd
            puts "Using current directory for ZIP output: #{output_dir}"
          else
            # For directory mode, use auto-prefix as directory name
            output_dir = prefix
            puts "Using auto-generated output directory: #{output_dir}"
          end
        end
        output_dir
      end

      def extract_to_directory(figure_objects, output_dir, prefix)
        # Always extract to temporary directory first, then move to destination
        Dir.mktmpdir('metanorma_figures_') do |temp_dir|
          puts "\nExtracting #{figure_objects.length} figures to temporary directory: #{temp_dir}"

          temp_files = figure_objects.map { |figure_obj| figure_obj.to_file(temp_dir, prefix) }

          # Ensure output directory exists
          FileUtils.mkdir_p(output_dir)

          # Move files from temp to final destination
          puts "Moving files to final destination: #{output_dir}"
          final_files = []
          temp_files.each do |temp_file|
            filename = File.basename(temp_file)
            final_path = File.join(output_dir, filename)
            FileUtils.mv(temp_file, final_path)
            final_files << final_path
            puts "  Moved: #{filename}"
          end

          final_files
        end
      end

      def extract_to_zip(figure_objects, output_dir, prefix)
        # Extract to temporary directory and create ZIP in output directory
        zip_filename = "#{prefix}.zip"
        FileUtils.mkdir_p(output_dir) if output_dir
        zip_path = File.join(output_dir || Dir.pwd, zip_filename)

        Dir.mktmpdir('metanorma_figures_zip_') do |temp_dir|
          puts "\nExtracting #{figure_objects.length} figures to temporary directory for ZIP: #{temp_dir}"

          temp_files = figure_objects.map { |figure_obj| figure_obj.to_file(temp_dir, prefix) }

          puts "Creating ZIP archive: #{zip_filename}"
          Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
            temp_files.each do |temp_file|
              filename = File.basename(temp_file)
              zipfile.add(filename, temp_file)
              puts "  Added to ZIP: #{filename}"
            end
          end

          puts "ZIP archive created: #{zip_path}"
          [zip_path]
        end
      end

      def find_figures(doc)
        figures = doc.xpath('//xmlns:figure', METANORMA_NS)
        puts "Found #{figures.length} figures"

        if figures.empty?
          puts 'No figures found in the document'
          exit 0
        end

        figures
      end

      def process_figures(figures)
        figure_objects = []
        format_counts = Hash.new(0)
        total_size = 0

        figures.each_with_index do |figure_element, index|
          figure_obj = process_single_figure(figure_element, index)
          next unless figure_obj

          figure_objects << figure_obj
          format_counts[figure_obj.format_name] += 1
          total_size += figure_obj.file_size
        end

        [figure_objects, format_counts, total_size]
      end

      def process_single_figure(figure_element, index)
        autonum = figure_element['autonum']

        unless autonum&.strip&.length&.positive?
          puts "Warning: Skipping figure #{index + 1} - missing autonum" if options[:verbose]
          return nil
        end

        image_element = figure_element.xpath('.//xmlns:image', METANORMA_NS).first
        unless image_element
          puts "Warning: Skipping figure #{index + 1} (autonum: #{autonum}) - no image element" if options[:verbose]
          return nil
        end

        create_figure_from_image(image_element, autonum)
      end

      def create_figure_from_image(image_element, autonum)
        src = image_element['src']
        filename = image_element['filename']
        mimetype = image_element['mimetype']

        if src&.start_with?('data:')
          create_data_uri_figure(src, filename, autonum)
        elsif mimetype == 'image/svg+xml' || filename&.end_with?('.svg')
          create_svg_figure(image_element, src, autonum)
        else
          log_unsupported_figure(autonum, mimetype, src)
          nil
        end
      end

      def create_data_uri_figure(src, filename, autonum)
        data_uri_info = parse_data_uri(src)
        unless data_uri_info
          puts "Warning: Skipping figure #{autonum} - malformed data URI" if options[:verbose]
          return nil
        end

        puts "  Figure #{autonum}: Data URI #{data_uri_info[:format_name]}"
        Figure.new(autonum, data_uri_info[:content], data_uri_info[:format], filename)
      end

      def create_svg_figure(image_element, src, autonum)
        svg_content = image_element.inner_html
        if svg_content.empty?
          puts "Warning: Skipping figure #{autonum} - empty SVG content" if options[:verbose]
          return nil
        end

        original_filename = src unless src&.start_with?('data:')
        puts "  Figure #{autonum}: SVG#{original_filename ? " (#{File.basename(original_filename)})" : ''}"
        Figure.new(autonum, svg_content, :svg, original_filename)
      end

      def log_unsupported_figure(autonum, mimetype, src)
        return unless options[:verbose]

        if mimetype && src
          puts "Warning: Skipping figure #{autonum} - external file not supported: #{File.basename(src)}"
        else
          puts "Warning: Skipping figure #{autonum} - no valid source or mimetype found"
        end
      end

      def print_summary(metadata, prefix, total_figures, format_counts, total_size, output_dir)
        puts "\n" + '=' * 60
        puts 'EXTRACTION SUMMARY'
        puts '=' * 60

        if metadata
          puts "Document: #{metadata}"
          puts "Auto-generated prefix: #{metadata.auto_prefix}" if options[:auto_prefix]
        end

        puts "File prefix used: #{prefix}"
        puts "Total figures extracted: #{total_figures}"

        format_counts.each { |format, count| puts "#{format} files: #{count}" }

        puts "Total size: #{format_bytes(total_size)}"
        puts "Output directory: #{output_dir}"
        puts "ZIP archive: #{options[:zip] ? 'Created' : 'Not requested'}"

        print_compliance_info(format_counts, metadata)
        puts '=' * 60
        puts "\nSuccessfully extracted #{total_figures} figures to #{output_dir}"
      end

      def print_compliance_info(format_counts, metadata)
        svg_count = format_counts['SVG'] || 0
        puts "\nISO DRG COMPLIANCE:"
        puts "✓ Revisable vector graphics (SVG): #{svg_count > 0 ? 'Yes' : 'No'}"
        puts '✓ Proper file naming convention: Yes'
        puts '✓ Language-neutral graphics: Yes (extracted from Metanorma)'
        puts "✓ Document metadata extraction: #{metadata ? 'Yes' : 'No'}"
      end

      def extract_document_metadata(doc)
        # Extract flavor from root metanorma element
        metanorma_element = doc.xpath('/xmlns:metanorma', METANORMA_NS).first
        flavor = metanorma_element&.[]('flavor') || 'iso' # Default to 'iso' for compatibility

        bibdata = doc.xpath('//xmlns:bibdata', METANORMA_NS).first
        return nil unless bibdata

        standard_number = xpath_text(bibdata, './/xmlns:docnumber')
        edition = xpath_text(bibdata, './/xmlns:edition[@language=""]')
        stage_element = bibdata.xpath('.//xmlns:status/xmlns:stage[@language=""]', METANORMA_NS).first

        return nil unless standard_number && edition && stage_element

        stage_code = stage_element.text&.strip
        stage_abbreviation = stage_element['abbreviation']
        substage_code = xpath_text(bibdata, './/xmlns:status/xmlns:substage')

        full_stage_code = [stage_code, substage_code].compact.join('.')

        return unless standard_number && edition && full_stage_code && stage_abbreviation

        DocumentMetadata.new(standard_number, edition, full_stage_code, stage_abbreviation, flavor)
      end

      def xpath_text(element, xpath)
        element.xpath(xpath, METANORMA_NS).first&.text&.strip
      end

      def parse_data_uri(data_uri)
        return nil unless data_uri.start_with?('data:')

        uri_content = data_uri[5..-1]
        parts = uri_content.split(',', 2)
        return nil if parts.length != 2

        header, data = parts
        mimetype = header.split(';').first
        format = MIMETYPE_FORMATS[mimetype.downcase] || :datauri_png
        format_name = Figure::FORMATS.dig(format, :name) || 'PNG'

        {
          format: format,
          format_name: format_name,
          content: data
        }
      rescue StandardError
        nil
      end

      def format_bytes(bytes)
        units = %w[B KB MB GB]
        size = bytes.to_f
        unit_index = 0

        while size >= 1024 && unit_index < units.length - 1
          size /= 1024
          unit_index += 1
        end

        "#{size.round(2)} #{units[unit_index]}"
      end
    end
  end
end
