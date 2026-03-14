# frozen_string_literal: true

RSpec.describe Legion::Extensions::Context::Helpers::Constants do
  it 'defines MAX_FRAMES' do
    expect(described_class::MAX_FRAMES).to eq(50)
  end

  it 'defines MAX_FRAME_STACK' do
    expect(described_class::MAX_FRAME_STACK).to eq(10)
  end

  it 'defines SWITCH_COST' do
    expect(described_class::SWITCH_COST).to eq(0.15)
  end

  it 'defines FAMILIARITY_ALPHA' do
    expect(described_class::FAMILIARITY_ALPHA).to eq(0.12)
  end

  it 'defines FRAME_LABELS covering 0.0..1.0' do
    labels = described_class::FRAME_LABELS
    [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0].each do |val|
      matched = labels.any? { |range, _| range.cover?(val) }
      expect(matched).to be(true), "Expected #{val} to match a label range"
    end
  end

  it 'has all expected FRAME_LABELS values' do
    values = described_class::FRAME_LABELS.values
    expect(values).to contain_exactly(:dominant, :active, :background, :fading)
  end
end
