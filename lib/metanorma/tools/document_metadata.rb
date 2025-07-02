# frozen_string_literal: true

require 'lutaml/model'

module Metanorma
  module Tools
    class DocumentMetadata < Lutaml::Model::Serializable
      attribute :title, :string
      attribute :docnumber, :string
      attribute :stage, :string
      attribute :substage, :string
      attribute :docidentifier, :string
      attribute :standard_number, :string
      attribute :part_number, :string
      attribute :edition, :string
      attribute :stage_code, :string
      attribute :stage_abbreviation, :string
      attribute :flavor, :string, default: -> { 'iso' }

      def auto_prefix
        case flavor
        when 'iso'
          # ISO DRG format: {StandardNumber}_{stageCode}_ed{editionNumber}
          "#{standard_number}_#{stage_abbreviation&.downcase}_ed#{edition}"
        else
          # For other flavors, use a generic pattern
          "#{flavor}_#{standard_number}_#{stage_abbreviation&.downcase}_ed#{edition}"
        end
      end

      def to_s
        if docidentifier
          "#{docidentifier} - #{title}"
        else
          "ISO #{standard_number} Edition #{edition} Stage #{stage_code} (#{stage_abbreviation})"
        end
      end
    end
  end
end
