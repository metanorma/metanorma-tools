# frozen_string_literal: true

require 'base64'
require 'fileutils'

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

      def to_file(output_dir, prefix)
        FileUtils.mkdir_p(output_dir)

        filename = generate_filename(prefix)
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

      def generate_filename(prefix)
        format_info = FORMATS[@format]
        extension = format_info ? format_info[:ext] : 'unknown'

        # Sanitize autonum for filename (remove dots for ISO DRG compliance)
        sanitized_autonum = @autonum.gsub('.', '')

        # ISO DRG format: {document_portion}_fig{figureNumber}.{extension}
        if @original_filename && !@original_filename.empty?
          basename = File.basename(@original_filename, File.extname(@original_filename))
          "#{prefix}_fig#{sanitized_autonum}_#{basename}.#{extension}"
        else
          "#{prefix}_fig#{sanitized_autonum}.#{extension}"
        end
      end
    end
  end
end
