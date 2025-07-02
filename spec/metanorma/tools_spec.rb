# frozen_string_literal: true

RSpec.describe Metanorma::Tools do
  it "has a version number" do
    expect(Metanorma::Tools::VERSION).not_to be nil
  end

  it "loads all required classes" do
    expect(Metanorma::Tools::FigureExtractor).to be_a(Class)
    expect(Metanorma::Tools::Figure).to be_a(Class)
    expect(Metanorma::Tools::DocumentMetadata).to be_a(Class)
    expect(Metanorma::Tools::IsoGraphicFilename).to be_a(Class)
    expect(Metanorma::Tools::Cli).to be_a(Class)
  end
end
