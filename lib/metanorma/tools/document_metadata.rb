# frozen_string_literal: true

module Metanorma
  module Tools
    class DocumentMetadata
      attr_reader :standard_number, :edition, :stage_code, :stage_abbreviation

      def initialize(standard_number, edition, stage_code, stage_abbreviation, flavor = 'generic')
        @standard_number = standard_number
        @edition = edition
        @stage_code = stage_code
        @stage_abbreviation = stage_abbreviation
        @flavor = flavor
      end

      def auto_prefix
        case @flavor
        when 'iso'
          "iso_#{@standard_number}_#{@stage_abbreviation.downcase}_#{@edition}_fig"
        else
          # For other flavors, use a generic pattern
          "#{@flavor}_#{@standard_number}_#{@stage_abbreviation.downcase}_#{@edition}_fig"
        end
      end

      def to_s
        "ISO #{@standard_number} Edition #{@edition} Stage #{@stage_code} (#{@stage_abbreviation})"
      end
    end
  end
end
