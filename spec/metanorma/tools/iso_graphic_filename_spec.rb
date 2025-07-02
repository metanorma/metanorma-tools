# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metanorma::Tools::IsoGraphicFilename do
  # Helper method to create filename objects with common defaults
  def create_filename(**attributes)
    defaults = {
      standard_number: 12345,
      part_number: 1,
      edition_number: 1,
      file_extension: 'dwg'
    }
    described_class.new(defaults.merge(attributes))
  end

  describe 'ISO DRG Section 3.2 Examples' do
    # Test cases from the README.adoc table
    [
      # Normal figures
      {
        description: 'File for figure 1',
        attributes: { content_type: 'figure', figure_number: '1' },
        expected: '12345-1_ed1fig1.dwg'
      },
      {
        description: 'File for figure 2',
        attributes: { content_type: 'figure', figure_number: '2' },
        expected: '12345-1_ed1fig2.dwg'
      },

      # Subfigures
      {
        description: 'File for figure 1, subfigure a',
        attributes: { content_type: 'figure', figure_number: '1', subfigure: 'a' },
        expected: '12345-1_ed1fig1a.dwg'
      },
      {
        description: 'File for figure 1, subfigure b',
        attributes: { content_type: 'figure', figure_number: '1', subfigure: 'b' },
        expected: '12345-1_ed1fig1b.dwg'
      },

      # Figure keys
      {
        description: 'File for figure 1, first key file',
        attributes: { content_type: 'key', figure_number: '1', key_number: 1 },
        expected: '12345-1_ed1fig1_key1.dwg'
      },
      {
        description: 'File for figure 1, second key file',
        attributes: { content_type: 'key', figure_number: '1', key_number: 2 },
        expected: '12345-1_ed1fig1_key2.dwg'
      },

      # Table figures
      {
        description: 'File for the single figure in Table 1',
        attributes: { content_type: 'table', figure_number: '1' },
        expected: '12345-1_ed1figTab1.dwg'
      },
      {
        description: 'File for the first figure in Table 1',
        attributes: { content_type: 'table', figure_number: '1a' },
        expected: '12345-1_ed1figTab1a.dwg'
      },
      {
        description: 'File for the second figure in Table 1',
        attributes: { content_type: 'table', figure_number: '1b' },
        expected: '12345-1_ed1figTab1b.dwg'
      },

      # Annex figures
      {
        description: 'File for the first figure in appendix A',
        attributes: { content_type: 'figure', figure_number: 'A1' },
        expected: '12345-1_ed1figA1.dwg'
      },
      {
        description: 'File for the second figure in appendix A',
        attributes: { content_type: 'figure', figure_number: 'A2' },
        expected: '12345-1_ed1figA2.dwg'
      },
      {
        description: 'File for first figure in appendix A, subfigure a',
        attributes: { content_type: 'figure', figure_number: 'A1', subfigure: 'a' },
        expected: '12345-1_ed1figA1a.dwg'
      },
      {
        description: 'File for first figure in appendix A, subfigure b',
        attributes: { content_type: 'figure', figure_number: 'A1', subfigure: 'b' },
        expected: '12345-1_ed1figA1b.dwg'
      },

      # Language variants
      {
        description: 'File for figure 1, French translation',
        attributes: { content_type: 'figure', figure_number: '1', language_code: 'f' },
        expected: '12345-1_ed1fig1_f.dwg'
      },

      # Amendments
      {
        description: 'File for figure 1 of amendment 1',
        attributes: { content_type: 'figure', figure_number: '1', supplement_type: 'amd', supplement_number: 1 },
        expected: '12345-1_ed1amd1fig1.dwg'
      },

      # Inline text graphics
      {
        description: 'File for graphical element inline with text',
        attributes: { content_type: 'text', text_number: 1 },
        expected: '12345-1_ed1figText1.dwg'
      },

      # Special layout
      {
        description: 'File for table 1 which does not have a figure',
        attributes: { content_type: 'special_layout', table_number: '1' },
        expected: 'SL12345-1_ed1figTab1.dwg'
      }
    ].each do |test_case|
      it test_case[:description] do
        filename = create_filename(**test_case[:attributes])
        expect(filename.to_s).to eq(test_case[:expected])
      end
    end
  end

  describe 'Additional scenarios' do
    it 'handles complex figure numbers with dots' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: 'A.2',
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345-1_ed1figA2.png')
    end

    it 'handles corrigenda' do
      filename = create_filename(
        part_number: 2,
        supplement_type: 'cor',
        supplement_number: 1,
        content_type: 'figure',
        figure_number: '1'
      )
      expect(filename.to_s).to eq('12345-2_ed1cor1fig1.dwg')
    end

    it 'handles amendment with stage code' do
      filename = create_filename(
        part_number: 2,
        supplement_type: 'amd',
        supplement_number: 2,
        stage_code: 'fdis',
        content_type: 'figure',
        figure_number: '1'
      )
      expect(filename.to_s).to eq('12345-2_ed1amd2_fdisfig1.dwg')
    end

    it 'handles different stage codes' do
      %w[pwi np awi wd cd dis fdis prf].each do |stage|
        filename = create_filename(
          stage_code: stage,
          content_type: 'figure',
          figure_number: '1'
        )
        expect(filename.to_s).to eq("12345-1_#{stage}_ed1fig1.dwg")
      end
    end

    it 'handles all language codes' do
      %w[e f r s a d].each do |lang|
        filename = create_filename(
          content_type: 'figure',
          figure_number: '1',
          language_code: lang
        )
        expect(filename.to_s).to eq("12345-1_ed1fig1_#{lang}.dwg")
      end
    end

    it 'handles standards without part numbers' do
      filename = create_filename(
        part_number: nil,
        content_type: 'figure',
        figure_number: 'A1',
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345_ed1figA1.png')
    end

    it 'handles different file extensions' do
      %w[svg png jpeg ai eps].each do |ext|
        filename = create_filename(
          content_type: 'figure',
          figure_number: '1',
          file_extension: ext
        )
        expect(filename.to_s).to eq("12345-1_ed1fig1.#{ext}")
      end
    end

    it 'handles different edition numbers' do
      filename = create_filename(
        edition_number: 3,
        content_type: 'figure',
        figure_number: 'A1',
        file_extension: 'svg'
      )
      expect(filename.to_s).to eq('12345-1_ed3figA1.svg')
    end
  end

  describe 'original filename preservation' do
    it 'generates extended pattern with original filename' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: '1',
        original_filename: 'diagram-overview.png',
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345-1_ed1fig1_diagram-overview.png')
    end

    it 'strips extension from original filename' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: 'A2',
        subfigure: 'a',
        original_filename: 'flowchart.svg',
        file_extension: 'svg'
      )
      expect(filename.to_s).to eq('12345-1_ed1figA2a_flowchart.svg')
    end

    it 'handles original filename with language code' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: '3',
        language_code: 'f',
        original_filename: 'schema.png',
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345-1_ed1fig3_f_schema.png')
    end

    it 'handles original filename with complex figure numbers' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: 'C.2',
        subfigure: 'b',
        original_filename: 'c2-b.png',
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345-1_ed1figC2b_c2-b.png')
    end

    it 'ignores empty original filename' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: '1',
        original_filename: '',
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345-1_ed1fig1.png')
    end

    it 'ignores nil original filename' do
      filename = create_filename(
        content_type: 'figure',
        figure_number: '1',
        original_filename: nil,
        file_extension: 'png'
      )
      expect(filename.to_s).to eq('12345-1_ed1fig1.png')
    end
  end

  describe 'serialization' do
    it 'can be serialized to hash' do
      filename = create_filename(
        stage_code: 'dis',
        content_type: 'figure',
        figure_number: 'A1',
        file_extension: 'png'
      )

      hash = filename.to_hash
      expect(hash['standard_number']).to eq(12345)
      expect(hash['part_number']).to eq(1)
      expect(hash['stage_code']).to eq('dis')
      expect(hash['edition_number']).to eq(1)
      expect(hash['content_type']).to eq('figure')
      expect(hash['figure_number']).to eq('A1')
      expect(hash['file_extension']).to eq('png')
    end

    it 'can be created from hash' do
      hash = {
        'standard_number' => 17301,
        'part_number' => 1,
        'stage_code' => 'dis',
        'edition_number' => 1,
        'content_type' => 'figure',
        'figure_number' => 'A1',
        'file_extension' => 'png'
      }

      filename = described_class.from_hash(hash)
      expect(filename.to_s).to eq('17301-1_dis_ed1figA1.png')
    end
  end
end
