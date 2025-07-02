# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metanorma::Tools::DocumentMetadata do
  describe 'initialization and attributes' do
    it 'creates metadata with all attributes' do
      metadata = described_class.new(
        title: 'Test Document Title',
        docnumber: '17301',
        stage: 'DRAFT International Standard',
        substage: '00',
        docidentifier: 'ISO/DIS 17301-1:2023',
        standard_number: '17301',
        part_number: '1',
        edition: '1',
        stage_code: 'dis',
        stage_abbreviation: 'DIS',
        flavor: 'iso'
      )

      expect(metadata.title).to eq('Test Document Title')
      expect(metadata.docnumber).to eq('17301')
      expect(metadata.stage).to eq('DRAFT International Standard')
      expect(metadata.substage).to eq('00')
      expect(metadata.docidentifier).to eq('ISO/DIS 17301-1:2023')
      expect(metadata.standard_number).to eq('17301')
      expect(metadata.part_number).to eq('1')
      expect(metadata.edition).to eq('1')
      expect(metadata.stage_code).to eq('dis')
      expect(metadata.stage_abbreviation).to eq('DIS')
      expect(metadata.flavor).to eq('iso')
    end

    it 'sets default flavor to iso' do
      metadata = described_class.new(
        title: 'Test Document',
        docnumber: '17301'
      )

      expect(metadata.flavor).to eq('iso')
    end

    it 'allows custom flavor' do
      metadata = described_class.new(
        title: 'Test Document',
        docnumber: '17301',
        flavor: 'iec'
      )

      expect(metadata.flavor).to eq('iec')
    end
  end

  describe 'auto_prefix generation' do
    context 'with ISO flavor' do
      it 'generates correct prefix for DIS stage' do
        metadata = described_class.new(
          standard_number: '17301',
          edition: '1',
          stage_abbreviation: 'DIS',
          flavor: 'iso'
        )

        expect(metadata.auto_prefix).to eq('17301_dis_ed1')
      end

      it 'generates correct prefix for PWI stage' do
        metadata = described_class.new(
          standard_number: '17301',
          edition: '1',
          stage_abbreviation: 'PWI',
          flavor: 'iso'
        )

        expect(metadata.auto_prefix).to eq('17301_pwi_ed1')
      end

      it 'generates correct prefix for FDIS stage' do
        metadata = described_class.new(
          standard_number: '17301',
          edition: '2',
          stage_abbreviation: 'FDIS',
          flavor: 'iso'
        )

        expect(metadata.auto_prefix).to eq('17301_fdis_ed2')
      end

      it 'handles nil stage_abbreviation gracefully' do
        metadata = described_class.new(
          standard_number: '17301',
          edition: '1',
          stage_abbreviation: nil,
          flavor: 'iso'
        )

        expect(metadata.auto_prefix).to eq('17301__ed1')
      end
    end

    context 'with other flavors' do
      it 'generates correct prefix for IEC flavor' do
        metadata = described_class.new(
          standard_number: '62304',
          edition: '1',
          stage_abbreviation: 'DIS',
          flavor: 'iec'
        )

        expect(metadata.auto_prefix).to eq('iec_62304_dis_ed1')
      end

      it 'generates correct prefix for custom flavor' do
        metadata = described_class.new(
          standard_number: '12345',
          edition: '1',
          stage_abbreviation: 'DRAFT',
          flavor: 'custom'
        )

        expect(metadata.auto_prefix).to eq('custom_12345_draft_ed1')
      end
    end
  end

  describe 'string representation' do
    context 'with docidentifier and title' do
      it 'formats with docidentifier and title' do
        metadata = described_class.new(
          title: 'Céréales et légumineuses — Spécification et méthodes d\'essai — Riz (DIS)',
          docidentifier: 'ISO/DIS 17301-1:2023'
        )

        expected = 'ISO/DIS 17301-1:2023 - Céréales et légumineuses — Spécification et méthodes d\'essai — Riz (DIS)'
        expect(metadata.to_s).to eq(expected)
      end
    end

    context 'without docidentifier' do
      it 'formats with standard information' do
        metadata = described_class.new(
          standard_number: '17301',
          edition: '1',
          stage_code: 'dis',
          stage_abbreviation: 'DIS'
        )

        expect(metadata.to_s).to eq('ISO 17301 Edition 1 Stage dis (DIS)')
      end
    end

    context 'with minimal information' do
      it 'handles missing fields gracefully' do
        metadata = described_class.new(
          title: 'Test Document'
        )

        expect(metadata.to_s).to eq('ISO  Edition  Stage  ()')
      end
    end
  end

  describe 'serialization' do
    it 'can be serialized to hash' do
      metadata = described_class.new(
        title: 'Test Document',
        docnumber: '17301',
        stage: 'DRAFT International Standard',
        substage: '00',
        docidentifier: 'ISO/DIS 17301-1:2023',
        standard_number: '17301',
        part_number: '1',
        edition: '1',
        stage_code: 'dis',
        stage_abbreviation: 'DIS',
        flavor: 'iso'
      )

      hash = metadata.to_hash
      expect(hash['title']).to eq('Test Document')
      expect(hash['docnumber']).to eq('17301')
      expect(hash['stage']).to eq('DRAFT International Standard')
      expect(hash['substage']).to eq('00')
      expect(hash['docidentifier']).to eq('ISO/DIS 17301-1:2023')
      expect(hash['standard_number']).to eq('17301')
      expect(hash['part_number']).to eq('1')
      expect(hash['edition']).to eq('1')
      expect(hash['stage_code']).to eq('dis')
      expect(hash['stage_abbreviation']).to eq('DIS')
      expect(hash['flavor']).to eq('iso')
    end

    it 'can be created from hash' do
      hash = {
        'title' => 'Test Document',
        'docnumber' => '17301',
        'stage' => 'DRAFT International Standard',
        'substage' => '00',
        'docidentifier' => 'ISO/DIS 17301-1:2023',
        'standard_number' => '17301',
        'part_number' => '1',
        'edition' => '1',
        'stage_code' => 'dis',
        'stage_abbreviation' => 'DIS',
        'flavor' => 'iso'
      }

      metadata = described_class.from_hash(hash)
      expect(metadata.title).to eq('Test Document')
      expect(metadata.docnumber).to eq('17301')
      expect(metadata.auto_prefix).to eq('17301_dis_ed1')
    end
  end

  describe 'real-world examples' do
    it 'handles fixture document metadata correctly' do
      metadata = described_class.new(
        title: 'Céréales et légumineuses — Spécification et méthodes d\'essai — Riz (DIS)',
        docnumber: '17301',
        stage: 'DRAFT International Standard',
        substage: '00',
        docidentifier: 'ISO/DIS 17301-1:2023',
        standard_number: '17301',
        part_number: '1',
        edition: '1',
        stage_code: 'dis',
        stage_abbreviation: 'DIS'
      )

      expect(metadata.auto_prefix).to eq('17301_dis_ed1')
      expect(metadata.to_s).to include('ISO/DIS 17301-1:2023')
      expect(metadata.to_s).to include('Céréales et légumineuses')
    end

    it 'handles multi-part standards' do
      metadata = described_class.new(
        title: 'Information technology — Security techniques — Part 3: Guidelines',
        docnumber: '27001',
        standard_number: '27001',
        part_number: '3',
        edition: '2',
        stage_code: 'fdis',
        stage_abbreviation: 'FDIS'
      )

      expect(metadata.auto_prefix).to eq('27001_fdis_ed2')
      expect(metadata.part_number).to eq('3')
    end

    it 'handles different document stages' do
      stages = [
        { code: 'pwi', abbr: 'PWI' },
        { code: 'nwip', abbr: 'NWIP' },
        { code: 'wd', abbr: 'WD' },
        { code: 'cd', abbr: 'CD' },
        { code: 'dis', abbr: 'DIS' },
        { code: 'fdis', abbr: 'FDIS' },
        { code: 'is', abbr: 'IS' }
      ]

      stages.each do |stage|
        metadata = described_class.new(
          standard_number: '12345',
          edition: '1',
          stage_code: stage[:code],
          stage_abbreviation: stage[:abbr]
        )

        expect(metadata.auto_prefix).to eq("12345_#{stage[:abbr].downcase}_ed1")
      end
    end
  end

  describe 'edge cases' do
    it 'handles empty strings' do
      metadata = described_class.new(
        title: '',
        docnumber: '',
        standard_number: '',
        edition: '',
        stage_abbreviation: ''
      )

      expect(metadata.auto_prefix).to eq('__ed')
      expect(metadata.to_s).to be_a(String)
    end

    it 'handles special characters in title' do
      metadata = described_class.new(
        title: 'Test — Document with "special" characters & symbols',
        docidentifier: 'ISO/DIS 12345:2023'
      )

      expect(metadata.to_s).to include('Test — Document with "special" characters & symbols')
    end

    it 'handles very long titles' do
      long_title = 'A' * 500
      metadata = described_class.new(
        title: long_title,
        docidentifier: 'ISO/DIS 12345:2023'
      )

      expect(metadata.to_s).to include(long_title)
    end
  end
end
