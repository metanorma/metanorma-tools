# frozen_string_literal: true

require 'base64'
require 'fileutils'
require_relative 'iso_graphic_filename'

module Metanorma
  module Tools
    class Figure
      FORMATS = {
        datauri_png: { name: 'PNG', ext: 'png', binary: true },
        datauri_jpeg: { name: 'JPEG', ext: 'jpg', binary: true },
        datauri_gif: { name: 'GIF', ext: 'gif', binary: true },
        datauri_svg: { name: 'SVG', ext: 'svg', binary: false },
        datauri_webp: { name: 'WebP', ext: 'webp', binary: true },
        svg: { name: 'SVG', ext: 'svg', binary: false }
      }.freeze

      attr_reader :autonum, :content, :format, :original_filename, :file_size

      def initialize(autonum, content, format, original_filename = nil)
        @autonum = autonum
        @content = content
        @format = format
        @original_filename = original_filename
        @file_size = calculate_size
      end

      def to_file(output_dir, prefix, document_metadata = nil, retain_original_filenames = false)
        FileUtils.mkdir_p(output_dir)

        filename = generate_filename(prefix, document_metadata, retain_original_filenames)
        filepath = File.join(output_dir, filename)

        write_content(filepath)
        puts "  Saved: #{filename}"
        filepath
      end

      def format_name
        FORMATS.dig(@format, :name) || @format.to_s.upcase
      end

      private

      def calculate_size
        case @format
        when *FORMATS.keys.select { |k| k.to_s.start_with?('datauri_') }
          Base64.decode64(@content).bytesize
        when :svg
          @content.bytesize
        else
          0
        end
      end

      def write_content(filepath)
        format_info = FORMATS[@format]
        return unless format_info

        mode = format_info[:binary] ? 'wb' : 'w'
        encoding = format_info[:binary] ? nil : 'utf-8'

        content_to_write = if @format.to_s.start_with?('datauri_')
                             Base64.decode64(@content)
                           else
                             @content
                           end

        File.open(filepath, mode, encoding: encoding) do |file|
          file.write(content_to_write)
        end
      end

      def generate_filename(prefix, document_metadata = nil, retain_original_filenames = false)
        format_info = FORMATS[@format]
        extension = format_info ? format_info[:ext] : 'unknown'

        # If we have document metadata, use proper ISO DRG filename generation
        if document_metadata
          # Parse subfigure from autonum (e.g., "C.2 a" -> figure: "C.2", subfigure: "a")
          figure_number, subfigure = parse_figure_number(@autonum)

          # Only include original filename if retain_original_filenames is true and we have an original filename
          original_filename_to_use = (retain_original_filenames && @original_filename && !@original_filename.empty?) ? @original_filename : nil

          iso_filename = IsoGraphicFilename.new(
            standard_number: document_metadata.standard_number&.to_i,
            part_number: document_metadata.part_number&.to_i,
            edition_number: document_metadata.edition&.to_i,
            stage_code: document_metadata.stage_code,
            content_type: 'figure',
            figure_number: figure_number,
            subfigure: subfigure,
            file_extension: extension,
            original_filename: original_filename_to_use
          )

          return iso_filename.generate_filename
        end

        # Fallback to simple prefix-based naming
        sanitized_autonum = @autonum.gsub('.', '')
        if @original_filename && !@original_filename.empty?
          basename = File.basename(@original_filename, File.extname(@original_filename))
          "#{prefix}fig#{sanitized_autonum}_#{basename}.#{extension}"
        else
          "#{prefix}fig#{sanitized_autonum}.#{extension}"
        end
      end

      def parse_figure_number(autonum)
        # Handle cases like "C.2 a", "A.1", "3", etc.
        if autonum.match(/^(.+?)\s+([a-z])$/)
          # Has subfigure: "C.2 a" -> ["C.2", "a"]
          [$1, $2]
        else
          # No subfigure: "C.2" -> ["C.2", nil]
          [autonum, nil]
        end
      end
    end
  end
end
