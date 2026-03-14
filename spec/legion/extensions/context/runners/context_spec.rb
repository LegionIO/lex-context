# frozen_string_literal: true

RSpec.describe Legion::Extensions::Context::Runners::Context do
  let(:client) { Legion::Extensions::Context::Client.new }

  describe '#create_context' do
    it 'returns success with frame data' do
      result = client.create_context(name: :work, domain: :task, cues: %i[code review])
      expect(result[:success]).to be true
      expect(result[:frame][:name]).to eq(:work)
      expect(result[:frame][:domain]).to eq(:task)
    end
  end

  describe '#activate_context' do
    it 'activates a frame by id' do
      frame = client.create_context(name: :work)[:frame]
      result = client.activate_context(frame_id: frame[:id])
      expect(result[:success]).to be true
      expect(result[:frame][:name]).to eq(:work)
    end

    it 'returns failure for unknown id' do
      result = client.activate_context(frame_id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'reports switch cost when changing frames' do
      f1 = client.create_context(name: :work)[:frame]
      f2 = client.create_context(name: :break)[:frame]
      client.activate_context(frame_id: f1[:id])
      result = client.activate_context(frame_id: f2[:id])
      expect(result[:switch_cost]).to be > 0.0
    end
  end

  describe '#detect_context' do
    before do
      client.create_context(name: :coding, cues: %i[code debug test])
      client.create_context(name: :ops, cues: %i[deploy monitor alert])
    end

    it 'returns matching candidates' do
      result = client.detect_context(input_cues: %i[code debug])
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
      expect(result[:best][:name]).to eq(:coding)
    end

    it 'returns empty when nothing matches' do
      result = client.detect_context(input_cues: %i[sleep dream])
      expect(result[:count]).to eq(0)
    end
  end

  describe '#auto_switch' do
    it 'switches to a better matching context' do
      f1 = client.create_context(name: :coding, cues: %i[code debug])[:frame]
      client.create_context(name: :ops, cues: %i[deploy monitor])
      client.activate_context(frame_id: f1[:id])

      result = client.auto_switch(input_cues: %i[deploy monitor alert])
      expect(result[:success]).to be true
      expect(result[:switched]).to be true
    end

    it 'does not switch when current is best' do
      f1 = client.create_context(name: :coding, cues: %i[code debug])[:frame]
      client.activate_context(frame_id: f1[:id])

      result = client.auto_switch(input_cues: %i[code debug])
      expect(result[:switched]).to be false
    end
  end

  describe '#current_context' do
    it 'returns nil when no frame is active' do
      result = client.current_context
      expect(result[:success]).to be true
      expect(result[:frame]).to be_nil
    end

    it 'returns the active frame' do
      f = client.create_context(name: :work)[:frame]
      client.activate_context(frame_id: f[:id])
      result = client.current_context
      expect(result[:frame][:name]).to eq(:work)
    end
  end

  describe '#update_context' do
    it 'decays and returns frame count' do
      client.create_context(name: :work)
      result = client.update_context
      expect(result[:success]).to be true
      expect(result[:frame_count]).to eq(1)
    end
  end

  describe '#add_cue' do
    it 'adds a cue to a frame' do
      f = client.create_context(name: :work, cues: %i[code])[:frame]
      result = client.add_cue(frame_id: f[:id], cue: :review)
      expect(result[:success]).to be true
      expect(result[:frame][:cues]).to include(:review)
    end

    it 'returns failure for unknown frame' do
      result = client.add_cue(frame_id: 'bad', cue: :test)
      expect(result[:success]).to be false
    end
  end

  describe '#frames_in_domain' do
    it 'returns frames for the given domain' do
      client.create_context(name: :a, domain: :task)
      client.create_context(name: :b, domain: :social)
      result = client.frames_in_domain(domain: :task)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#remove_context' do
    it 'removes a frame' do
      f = client.create_context(name: :work)[:frame]
      result = client.remove_context(frame_id: f[:id])
      expect(result[:success]).to be true
      expect(client.context_stats[:stats][:frame_count]).to eq(0)
    end
  end

  describe '#context_stats' do
    it 'returns summary statistics' do
      client.create_context(name: :work, domain: :task)
      result = client.context_stats
      expect(result[:success]).to be true
      expect(result[:stats][:frame_count]).to eq(1)
      expect(result[:stats]).to have_key(:by_domain)
    end
  end
end
