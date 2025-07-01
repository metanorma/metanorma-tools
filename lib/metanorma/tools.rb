# frozen_string_literal: true

require_relative "tools/version"
require_relative "tools/document_metadata"
require_relative "tools/iso_graphic_filename"
require_relative "tools/figure"
require_relative "tools/figure_extractor"
require_relative "tools/commands"
require_relative "tools/commands/extract_images"
require_relative "tools/cli"

module Metanorma
  module Tools
    class Error < StandardError; end
  end
end
