# frozen_string_literal: true

RSpec.describe Legion::Extensions::Context::Helpers::Frame do
  let(:frame) { described_class.new(name: :work, domain: :task, cues: %i[code review debug]) }

  describe '#initialize' do
    it 'sets name and domain' do
      expect(frame.name).to eq(:work)
      expect(frame.domain).to eq(:task)
    end

    it 'starts with strength 1.0' do
      expect(frame.strength).to eq(1.0)
    end

    it 'starts with default familiarity' do
      expect(frame.familiarity).to be_within(0.01).of(Legion::Extensions::Context::Helpers::Constants::DEFAULT_FAMILIARITY)
    end

    it 'stores cues' do
      expect(frame.cues).to eq(%i[code review debug])
    end

    it 'starts with zero activation count' do
      expect(frame.activation_count).to eq(0)
    end

    it 'has a UUID id' do
      expect(frame.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'caps cues at MAX_CUES_PER_FRAME' do
      many_cues = (1..50).map { |i| :"cue_#{i}" }
      f = described_class.new(name: :big, cues: many_cues)
      expect(f.cues.size).to eq(Legion::Extensions::Context::Helpers::Constants::MAX_CUES_PER_FRAME)
    end
  end

  describe '#activate' do
    it 'increments activation count' do
      frame.activate
      expect(frame.activation_count).to eq(1)
    end

    it 'updates last_activated' do
      before = frame.last_activated
      sleep 0.01
      frame.activate
      expect(frame.last_activated).to be >= before
    end

    it 'increases familiarity' do
      initial = frame.familiarity
      frame.activate
      expect(frame.familiarity).to be > initial
    end
  end

  describe '#deactivate' do
    it 'decreases familiarity' do
      frame.activate
      raised = frame.familiarity
      frame.deactivate
      expect(frame.familiarity).to be < raised
    end
  end

  describe '#decay' do
    it 'reduces strength' do
      initial = frame.strength
      frame.decay
      expect(frame.strength).to be < initial
    end

    it 'does not go below zero' do
      100.times { frame.decay }
      expect(frame.strength).to be >= 0.0
    end
  end

  describe '#match_score' do
    it 'returns 1.0 for perfect match' do
      expect(frame.match_score(%i[code review debug])).to eq(1.0)
    end

    it 'returns partial score for partial match' do
      score = frame.match_score(%i[code deploy])
      expect(score).to be_within(0.01).of(1.0 / 3.0)
    end

    it 'returns 0.0 for no overlap' do
      expect(frame.match_score(%i[sleep eat])).to eq(0.0)
    end

    it 'returns 0.0 for empty input' do
      expect(frame.match_score([])).to eq(0.0)
    end

    it 'returns 0.0 for frame with no cues' do
      empty = described_class.new(name: :empty)
      expect(empty.match_score(%i[code])).to eq(0.0)
    end
  end

  describe '#add_cue' do
    it 'adds a new cue' do
      frame.add_cue(:deploy)
      expect(frame.cues).to include(:deploy)
    end

    it 'does not duplicate existing cue' do
      frame.add_cue(:code)
      expect(frame.cues.count(:code)).to eq(1)
    end

    it 'caps cues at MAX_CUES_PER_FRAME' do
      40.times { |i| frame.add_cue(:"extra_#{i}") }
      expect(frame.cues.size).to be <= Legion::Extensions::Context::Helpers::Constants::MAX_CUES_PER_FRAME
    end
  end

  describe '#remove_cue' do
    it 'removes the specified cue' do
      frame.remove_cue(:code)
      expect(frame.cues).not_to include(:code)
    end
  end

  describe '#label' do
    it 'returns :dominant for fresh frame' do
      expect(frame.label).to eq(:dominant)
    end

    it 'returns :fading for heavily decayed frame' do
      60.times { frame.decay }
      expect(frame.label).to eq(:fading)
    end
  end

  describe '#stale?' do
    it 'is not stale when fresh' do
      expect(frame.stale?).to be false
    end

    it 'becomes stale after heavy decay' do
      100.times { frame.decay }
      expect(frame.stale?).to be true
    end
  end

  describe '#to_h' do
    it 'contains all expected keys' do
      h = frame.to_h
      expect(h).to have_key(:id)
      expect(h).to have_key(:name)
      expect(h).to have_key(:domain)
      expect(h).to have_key(:strength)
      expect(h).to have_key(:familiarity)
      expect(h).to have_key(:label)
      expect(h).to have_key(:cues)
      expect(h).to have_key(:activation_count)
    end
  end
end
