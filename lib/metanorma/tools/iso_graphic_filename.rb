# frozen_string_literal: true

require 'lutaml/model'

module Metanorma
  module Tools
    class IsoGraphicFilename < Lutaml::Model::Serializable
      VALID_STAGE_CODES = %w[pwi np awi wd cd dis fdis prf].freeze
      VALID_SUPPLEMENT_TYPES = %w[amd cor].freeze
      VALID_CONTENT_TYPES = %w[figure table key text special_layout].freeze
      VALID_LANGUAGE_CODES = %w[e f r s a d].freeze

      attribute :standard_number, :integer
      attribute :part_number, :integer
      attribute :edition_number, :integer
      attribute :stage_code, :string, values: VALID_STAGE_CODES
      attribute :supplement_type, :string, values: VALID_SUPPLEMENT_TYPES
      attribute :supplement_number, :integer
      attribute :content_type, :string, values: VALID_CONTENT_TYPES
      attribute :figure_number, :string
      attribute :subfigure, :string
      attribute :table_number, :string
      attribute :key_number, :integer
      attribute :text_number, :integer
      attribute :language_code, :string, values: VALID_LANGUAGE_CODES
      attribute :file_extension, :string
      attribute :original_filename, :string

      key_value do
        map 'standard_number', to: :standard_number
        map 'part_number', to: :part_number
        map 'edition_number', to: :edition_number
        map 'stage_code', to: :stage_code
        map 'supplement_type', to: :supplement_type
        map 'supplement_number', to: :supplement_number
        map 'content_type', to: :content_type
        map 'figure_number', to: :figure_number
        map 'subfigure', to: :subfigure
        map 'table_number', to: :table_number
        map 'key_number', to: :key_number
        map 'text_number', to: :text_number
        map 'language_code', to: :language_code
        map 'file_extension', to: :file_extension
        map 'original_filename', to: :original_filename
      end

      def generate_filename
        document_portion = build_document_portion
        content_portion = build_content_portion
        language_portion = build_language_portion
        original_portion = build_original_filename_portion

        filename_parts = [document_portion, content_portion, language_portion, original_portion].compact
        filename = filename_parts.join('')

        "#{filename}.#{file_extension}"
      end

      def to_s
        generate_filename
      end

      def inspect
        attrs = {
          standard_number: standard_number,
          part_number: part_number,
          edition_number: edition_number,
          stage_code: stage_code,
          supplement_type: supplement_type,
          supplement_number: supplement_number,
          content_type: content_type,
          figure_number: figure_number,
          subfigure: subfigure,
          table_number: table_number,
          key_number: key_number,
          text_number: text_number,
          language_code: language_code,
          file_extension: file_extension
        }.compact
        "#<IsoGraphicFilename #{attrs}>"
      end

      private

      def build_document_portion
        # Handle special layout prefix
        prefix = content_type == 'special_layout' ? 'SL' : ''

        # Build standard number with optional part
        doc_id = "#{prefix}#{standard_number}"
        doc_id += "-#{part_number}" if part_number

        # Add stage code if present (before edition for standards, after supplement for amendments)
        if supplement_type
          # Amendment/Corrigenda pattern: {StandardNumber}-{partNumber}_ed{editionNumber}{supplementCode}{supplementNumber}[_{stageCode}]
          doc_id += "_ed#{edition_number}#{supplement_type}#{supplement_number}"
          doc_id += "_#{stage_code}" if stage_code
        else
          # Standard pattern: {StandardNumber}[-{partNumber}]_ed{editionNumber}[_{stageCode}]
          doc_id += if stage_code
                      "_#{stage_code}_ed#{edition_number}"
                    else
                      "_ed#{edition_number}"
                    end
        end

        doc_id
      end

      def build_content_portion
        case content_type
        when 'figure'
          content = "fig#{normalize_figure_number(figure_number)}"
          content += subfigure if subfigure
          content
        when 'table'
          "figTab#{normalize_figure_number(table_number || figure_number)}"
        when 'key'
          "fig#{normalize_figure_number(figure_number)}_key#{key_number}"
        when 'text'
          "figText#{text_number}"
        when 'special_layout'
          "figTab#{normalize_figure_number(table_number || figure_number)}"
        else
          raise ArgumentError, "Unknown content_type: #{content_type}"
        end
      end

      def build_language_portion
        language_code ? "_#{language_code}" : nil
      end

      def build_original_filename_portion
        return nil unless original_filename && !original_filename.empty?

        # Remove file extension from original filename if present
        clean_filename = File.basename(original_filename, '.*')
        "_#{clean_filename}"
      end

      def normalize_figure_number(figure_num)
        return '' unless figure_num

        # Convert "A.2" to "A2", "3" to "3", etc.
        figure_num.to_s.gsub('.', '')
      end
    end
  end
end
