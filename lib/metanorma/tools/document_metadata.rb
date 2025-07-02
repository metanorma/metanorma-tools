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
          # ISO DRG format: {StandardNumber}_ed{editionNumber}_{stageCode}
          "#{@standard_number}_ed#{@edition}_#{@stage_abbreviation.downcase}"
        else
          # For other flavors, use a generic pattern
          "#{@flavor}_#{@standard_number}_ed#{@edition}_#{@stage_abbreviation.downcase}"
        end
      end

      def to_s
        "ISO #{@standard_number} Edition #{@edition} Stage #{@stage_code} (#{@stage_abbreviation})"
      end
    end
  end
end
