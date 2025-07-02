# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'zip'

RSpec.describe Metanorma::Tools::FigureExtractor do
  let(:fixture_path) { File.join(__dir__, '../../fixtures/document-en.dis.presentation.xml') }
  let(:extractor) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir) }

  describe '#extract' do
    context 'with the fixture document containing figures in annexes' do
      it 'extracts all figures from the document' do
        # Capture output to verify extraction
        output = capture_stdout do
          extractor.extract(fixture_path, temp_dir)
        end

        expect(output).to include('Found 6 figures')
        expect(output).to include('Successfully extracted 6 figures')

        # Verify files were created
        png_files = Dir.glob(File.join(temp_dir, '*.png'))
        expect(png_files.length).to eq(6)
      end

      it 'extracts document metadata correctly' do
        output = capture_stdout do
          extractor.extract(fixture_path, temp_dir)
        end

        expect(output).to include('ISO/DIS 17301-1:2023')
        expect(output).to include('Auto-generated prefix: 17301_dis_ed3')
        expect(output).to include('Document metadata extraction: Yes')
      end

      describe 'figure extraction details' do
        before do
          capture_stdout { extractor.extract(fixture_path, temp_dir) }
        end

        it 'extracts all 6 figures with correct data' do
          png_files = Dir.glob(File.join(temp_dir, '*.png'))
          expect(png_files.length).to eq(6)

          # Verify all files have content
          png_files.each do |file|
            expect(File.size(file)).to be > 1000 # PNG files should be reasonably sized
          end
        end

        it 'generates correct ISO graphic filenames for all figures' do
          png_files = Dir.glob(File.join(temp_dir, '*.png')).map { |f| File.basename(f) }

          # All files should follow the ISO DRG pattern
          png_files.each do |filename|
            expect(filename).to match(/^17301_dis_ed3fig.+\.png$/)
          end

          # Check for specific expected patterns
          expect(png_files.any? { |f| f.match(/figA1/) }).to be true
          expect(png_files.any? { |f| f.match(/figC1/) }).to be true
          expect(png_files.any? { |f| f.match(/figC2/) }).to be true
        end
      end

      describe 'image format and data validation' do
        before do
          capture_stdout { extractor.extract(fixture_path, temp_dir) }
        end

        it 'correctly processes all images as PNG with valid data' do
          png_files = Dir.glob(File.join(temp_dir, '*.png'))

          png_files.each do |file|
            # Verify PNG file signature
            File.open(file, 'rb') do |f|
              signature = f.read(8)
              expected_signature = "\x89PNG\r\n\x1A\n".dup.force_encoding('ASCII-8BIT')
              expect(signature).to eq(expected_signature)
            end
          end
        end
      end

      describe 'archive creation' do
        let(:zip_extractor) { described_class.new(zip: true) }

        it 'creates a zip archive with all figures' do
          output = capture_stdout do
            zip_extractor.extract(fixture_path, temp_dir)
          end

          expect(output).to include('ZIP archive created')

          zip_files = Dir.glob(File.join(temp_dir, '*.zip'))
          expect(zip_files.length).to eq(1)

          Zip::File.open(zip_files.first) do |zip_file|
            expect(zip_file.entries.length).to eq(6)

            zip_file.entries.each do |entry|
              expect(entry.name).to match(/^17301_dis_ed3fig.+\.png$/)
              expect(entry.size).to be > 0
            end
          end
        end

        it 'creates correctly named files in archive' do
          capture_stdout do
            zip_extractor.extract(fixture_path, temp_dir)
          end

          zip_files = Dir.glob(File.join(temp_dir, '*.zip'))

          Zip::File.open(zip_files.first) do |zip_file|
            filenames = zip_file.entries.map(&:name).sort

            # Verify we have the expected number of files
            expect(filenames.length).to eq(6)

            # All should be PNG files with proper naming
            filenames.each do |filename|
              expect(filename).to match(/^17301_dis_ed3fig.+\.png$/)
            end
          end
        end
      end
    end

    context 'with error handling' do
      it 'exits for non-existent file' do
        expect do
          capture_stdout { extractor.extract('non_existent.xml') }
        end.to raise_error(SystemExit)
      end

      it 'handles malformed XML gracefully' do
        malformed_xml = Tempfile.new(['malformed', '.xml'])
        malformed_xml.write('not valid xml content')
        malformed_xml.close

        expect do
          capture_stdout { extractor.extract(malformed_xml.path) }
        end.to raise_error(SystemExit)
      ensure
        malformed_xml&.unlink
      end
    end

    context 'with CLI integration' do
      it 'works with the CLI extract-images command' do
        # Test that the CLI can process the fixture file
        output = `bundle exec metanorma-tools extract-images #{fixture_path} --output-dir #{temp_dir} 2>&1`
        expect($?.success?).to be true

        # Verify files were created
        png_files = Dir.glob(File.join(temp_dir, '*.png'))
        expect(png_files.length).to eq(6)
      end
    end
  end

  describe 'individual component testing' do
    describe Metanorma::Tools::Figure do
      it 'creates figure with valid data' do
        figure = described_class.new(
          'A.1',
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
          :datauri_png,
          'test-figure.png'
        )

        expect(figure.autonum).to eq('A.1')
        expect(figure.format).to eq(:datauri_png)
        expect(figure.content).not_to be_empty
        expect(figure.original_filename).to eq('test-figure.png')
      end
    end

    describe Metanorma::Tools::DocumentMetadata do
      it 'creates metadata with valid data' do
        metadata = described_class.new(
          title: 'Test Document',
          docnumber: '12345',
          stage: 'DRAFT',
          substage: '00',
          docidentifier: 'ISO/DIS 12345:2023',
          standard_number: '12345',
          part_number: '1',
          edition: '1',
          stage_code: 'dis',
          stage_abbreviation: 'DIS'
        )

        expect(metadata.title).to eq('Test Document')
        expect(metadata.docnumber).to eq('12345')
        expect(metadata.stage).to eq('DRAFT')
        expect(metadata.auto_prefix).to eq('12345_dis_ed1')
      end
    end

    describe Metanorma::Tools::IsoGraphicFilename do
      it 'generates correct filename format' do
        filename = described_class.new(
          standard_number: 17301,
          part_number: 1,
          stage_code: 'dis',
          edition_number: 3,
          content_type: 'figure',
          figure_number: 'A1',
          original_filename: 'figureA-1.png',
          file_extension: 'png'
        )

        expect(filename.to_s).to eq('17301-1_dis_ed3figA1_figureA-1.png')
      end

      it 'handles UUID-based figure IDs' do
        filename = described_class.new(
          standard_number: 17301,
          part_number: 1,
          stage_code: 'dis',
          edition_number: 3,
          content_type: 'text',
          text_number: 1,
          original_filename: '_85f711f6-478d-a680-b5b9-3bc85332dfd1.png',
          file_extension: 'png'
        )

        expect(filename.to_s).to eq('17301-1_dis_ed3figText1__85f711f6-478d-a680-b5b9-3bc85332dfd1.png')
      end

      it 'handles subfigure naming correctly' do
        filename = described_class.new(
          standard_number: 17301,
          part_number: 1,
          stage_code: 'dis',
          edition_number: 3,
          content_type: 'figure',
          figure_number: 'C2',
          subfigure: 'a',
          original_filename: 'figureC-2-a.png',
          file_extension: 'png'
        )

        expect(filename.to_s).to eq('17301-1_dis_ed3figC2a_figureC-2-a.png')
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
