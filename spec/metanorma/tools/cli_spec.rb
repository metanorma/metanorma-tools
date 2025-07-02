# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Metanorma::Tools::Cli do
  let(:fixture_path) { File.join(__dir__, '../../fixtures/document-en.dis.presentation.xml') }
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_path) { File.join(temp_dir, 'test_output.zip') }

  after { FileUtils.rm_rf(temp_dir) }

  describe '#extract_images' do
    it 'extracts images from fixture document' do
      cli = described_class.new
      cli.options = { output_dir: temp_dir, zip: false }
      cli.extract_images(fixture_path)

      # Verify files were created
      png_files = Dir.glob(File.join(temp_dir, '*.png'))
      expect(png_files.length).to eq(6)

      # Check for expected filenames
      filenames = png_files.map { |f| File.basename(f) }
      expect(filenames.any? { |f| f.include?('figA1') }).to be true
      expect(filenames.any? { |f| f.include?('figC1') }).to be true
      expect(filenames.any? { |f| f.include?('figC2') }).to be true
    end

    it 'shows help when no arguments provided' do
      expect { described_class.start([]) }.to output(/Commands:/).to_stdout
    end

    it 'shows help for extract-images command' do
      expect { described_class.start(['help', 'extract-images']) }.to output(/Usage:/).to_stdout
    end

    it 'handles invalid input file' do
      cli = described_class.new
      cli.options = { output_dir: temp_dir }
      expect { cli.extract_images('non_existent.xml') }.to raise_error(SystemExit)
    end

    it 'creates output directory if it does not exist' do
      nested_output = File.join(temp_dir, 'nested', 'dir')

      cli = described_class.new
      cli.options = { output_dir: nested_output }
      cli.extract_images(fixture_path)

      expect(Dir.exist?(nested_output)).to be true
      png_files = Dir.glob(File.join(nested_output, '*.png'))
      expect(png_files.length).to eq(6)
    end

    it 'retains original filenames when option is enabled for ISO documents' do
      cli = described_class.new
      cli.options = { output_dir: temp_dir, retain_original_filenames: true }
      cli.extract_images(fixture_path)

      png_files = Dir.glob(File.join(temp_dir, '*.png'))
      filenames = png_files.map { |f| File.basename(f) }

      # Should include original filename parts
      expect(filenames.any? { |f| f.include?('_a1.png') }).to be true
      expect(filenames.any? { |f| f.include?('_b1.png') }).to be true
      expect(filenames.any? { |f| f.include?('_c2-a.png') }).to be true
      expect(filenames.any? { |f| f.include?('_c2-b.png') }).to be true
      expect(filenames.any? { |f| f.include?('_c2-c.png') }).to be true
    end

    it 'does not retain original filenames when option is disabled' do
      cli = described_class.new
      cli.options = { output_dir: temp_dir, retain_original_filenames: false }
      cli.extract_images(fixture_path)

      png_files = Dir.glob(File.join(temp_dir, '*.png'))
      filenames = png_files.map { |f| File.basename(f) }

      # Should NOT include original filename parts
      expect(filenames.any? { |f| f.include?('_a1.png') }).to be false
      expect(filenames.any? { |f| f.include?('_b1.png') }).to be false
      expect(filenames.any? { |f| f.include?('_c2-a.png') }).to be false
    end
  end

  describe 'command line integration' do
    it 'can be executed via command line' do
      # Test the actual CLI execution using Open3 for cross-platform compatibility
      require 'open3'

      stdout, stderr, status = Open3.capture3("bundle exec metanorma-tools extract-images #{fixture_path} --output-dir #{temp_dir}")

      expect(status.success?).to be true
      expect(stdout).to include('Successfully extracted')
    end

    it 'shows version information' do
      expect { described_class.start(['--version']) }.to output(/#{Metanorma::Tools::VERSION}/).to_stdout
    end
  end
end
