# frozen_string_literal: true

module Metanorma
  module Tools
    class IsoGraphicFilename
      VALID_STAGE_CODES = %w[pwi np awi wd cd dis fdis prf].freeze
      VALID_SUPPLEMENT_TYPES = %w[amd cor].freeze
      VALID_CONTENT_TYPES = %w[figure table key text special_layout].freeze
      VALID_LANGUAGE_CODES = %w[e f r s a d].freeze

      attr_reader :standard_number, :part_number, :edition_number, :stage_code,
                  :supplement_type, :supplement_number, :content_type,
                  :figure_number, :subfigure, :table_number, :key_number, :text_number,
                  :language_code, :file_extension

      def initialize(data)
        @data = data.is_a?(Hash) ? data : {}
        parse_and_validate_data
      end

      def generate_filename
        validate!

        document_portion = build_document_portion
        content_portion = build_content_portion
        language_portion = build_language_portion

        filename_parts = [document_portion, content_portion, language_portion].compact
        filename = filename_parts.join('')

        "#{filename}.#{@file_extension}"
      end

      def validate!
        errors = []

        # Required fields
        errors << 'standard_number is required' unless @standard_number
        errors << 'edition_number is required' unless @edition_number
        errors << 'content_type is required' unless @content_type
        errors << 'file_extension is required' unless @file_extension

        # Valid enums
        if @stage_code && !VALID_STAGE_CODES.include?(@stage_code)
          errors << "stage_code must be one of: #{VALID_STAGE_CODES.join(', ')}"
        end

        if @supplement_type && !VALID_SUPPLEMENT_TYPES.include?(@supplement_type)
          errors << "supplement_type must be one of: #{VALID_SUPPLEMENT_TYPES.join(', ')}"
        end

        if @content_type && !VALID_CONTENT_TYPES.include?(@content_type)
          errors << "content_type must be one of: #{VALID_CONTENT_TYPES.join(', ')}"
        end

        if @language_code && !VALID_LANGUAGE_CODES.include?(@language_code)
          errors << "language_code must be one of: #{VALID_LANGUAGE_CODES.join(', ')}"
        end

        # Conditional requirements
        if @supplement_type && !@supplement_number
          errors << 'supplement_number is required when supplement_type is specified'
        end

        if @supplement_number && !@supplement_type
          errors << 'supplement_type is required when supplement_number is specified'
        end

        # Content type specific validations
        case @content_type
        when 'figure', 'table', 'key'
          errors << "figure_number is required for #{@content_type} content_type" unless @figure_number
        when 'text'
          errors << 'text_number is required for text content_type' unless @text_number
        end

        errors << 'key_number is required for key content_type' if @content_type == 'key' && !@key_number

        errors << 'subfigure is only valid for figure content_type' if @subfigure && @content_type != 'figure'

        if @subfigure && (@subfigure.length != 1 || !@subfigure.match?(/[a-z]/))
          errors << 'subfigure must be a single lowercase letter'
        end

        raise ArgumentError, "Validation errors: #{errors.join('; ')}" unless errors.empty?
      end

      def to_h
        {
          standard_number: @standard_number,
          part_number: @part_number,
          edition_number: @edition_number,
          stage_code: @stage_code,
          supplement_type: @supplement_type,
          supplement_number: @supplement_number,
          content_type: @content_type,
          figure_number: @figure_number,
          subfigure: @subfigure,
          table_number: @table_number,
          key_number: @key_number,
          text_number: @text_number,
          language_code: @language_code,
          file_extension: @file_extension
        }.compact
      end

      def inspect
        "#<IsoGraphicFilename #{to_h}>"
      end

      private

      def parse_and_validate_data
        @standard_number = parse_integer(@data['standard_number'] || @data[:standard_number])
        @part_number = parse_integer(@data['part_number'] || @data[:part_number])
        @edition_number = parse_integer(@data['edition_number'] || @data[:edition_number])
        @stage_code = parse_string(@data['stage_code'] || @data[:stage_code])
        @supplement_type = parse_string(@data['supplement_type'] || @data[:supplement_type])
        @supplement_number = parse_integer(@data['supplement_number'] || @data[:supplement_number])
        @content_type = parse_string(@data['content_type'] || @data[:content_type])
        @figure_number = parse_string(@data['figure_number'] || @data[:figure_number])
        @subfigure = parse_string(@data['subfigure'] || @data[:subfigure])
        @table_number = parse_string(@data['table_number'] || @data[:table_number])
        @key_number = parse_integer(@data['key_number'] || @data[:key_number])
        @text_number = parse_integer(@data['text_number'] || @data[:text_number])
        @language_code = parse_string(@data['language_code'] || @data[:language_code])
        @file_extension = parse_string(@data['file_extension'] || @data[:file_extension])
      end

      def parse_integer(value)
        return nil if value.nil? || value == ''

        value.is_a?(Integer) ? value : value.to_i
      end

      def parse_string(value)
        return nil if value.nil? || value == ''

        value.to_s.strip
      end

      def build_document_portion
        # Handle special layout prefix
        prefix = @content_type == 'special_layout' ? 'SL' : ''

        # Build standard number with optional part
        doc_id = "#{prefix}#{@standard_number}"
        doc_id += "-#{@part_number}" if @part_number

        # Add stage code if present (before edition for standards, after supplement for amendments)
        if @supplement_type
          # Amendment/Corrigenda pattern: {StandardNumber}-{partNumber}_ed{editionNumber}{supplementCode}{supplementNumber}[_{stageCode}]
          doc_id += "_ed#{@edition_number}#{@supplement_type}#{@supplement_number}"
          doc_id += "_#{@stage_code}" if @stage_code
        else
          # Standard pattern: {StandardNumber}[-{partNumber}]_ed{editionNumber}[_{stageCode}]
          doc_id += if @stage_code
                      "_#{@stage_code}_ed#{@edition_number}"
                    else
                      "_ed#{@edition_number}"
                    end
        end

        doc_id
      end

      def build_content_portion
        case @content_type
        when 'figure'
          content = "fig#{normalize_figure_number(@figure_number)}"
          content += @subfigure if @subfigure
          content
        when 'table'
          "figTab#{normalize_figure_number(@table_number || @figure_number)}"
        when 'key'
          "fig#{normalize_figure_number(@figure_number)}_key#{@key_number}"
        when 'text'
          "figText#{@text_number}"
        when 'special_layout'
          "figTab#{normalize_figure_number(@table_number || @figure_number)}"
        else
          raise ArgumentError, "Unknown content_type: #{@content_type}"
        end
      end

      def build_language_portion
        @language_code ? "_#{@language_code}" : nil
      end

      def normalize_figure_number(figure_num)
        return '' unless figure_num

        # Convert "A.2" to "A2", "3" to "3", etc.
        figure_num.to_s.gsub('.', '')
      end
    end
  end
end
