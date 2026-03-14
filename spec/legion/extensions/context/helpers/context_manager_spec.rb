# frozen_string_literal: true

RSpec.describe Legion::Extensions::Context::Helpers::ContextManager do
  let(:manager) { described_class.new }

  describe '#create_frame' do
    it 'creates and stores a frame' do
      frame = manager.create_frame(name: :work, domain: :task, cues: %i[code review])
      expect(frame).to be_a(Legion::Extensions::Context::Helpers::Frame)
      expect(manager.frames.size).to eq(1)
    end

    it 'trims frames when exceeding MAX_FRAMES' do
      max = Legion::Extensions::Context::Helpers::Constants::MAX_FRAMES
      (max + 5).times { |i| manager.create_frame(name: :"frame_#{i}") }
      expect(manager.frames.size).to eq(max)
    end
  end

  describe '#activate' do
    let(:frame) { manager.create_frame(name: :work, cues: %i[code]) }

    it 'activates a frame and pushes to stack' do
      result = manager.activate(frame.id)
      expect(result[:frame]).to eq(frame)
      expect(manager.current_frame).to eq(frame)
    end

    it 'returns nil for unknown frame' do
      expect(manager.activate('nonexistent')).to be_nil
    end

    it 'computes switch cost when changing frames' do
      f1 = manager.create_frame(name: :work, cues: %i[code])
      f2 = manager.create_frame(name: :meeting, cues: %i[discuss])
      manager.activate(f1.id)
      result = manager.activate(f2.id)
      expect(result[:switch_cost]).to be_a(Float)
      expect(result[:switch_cost]).to be > 0.0
    end

    it 'records switch history' do
      f1 = manager.create_frame(name: :work)
      f2 = manager.create_frame(name: :break)
      manager.activate(f1.id)
      manager.activate(f2.id)
      expect(manager.switch_history.size).to eq(1)
    end

    it 'caps the active stack at MAX_FRAME_STACK' do
      max = Legion::Extensions::Context::Helpers::Constants::MAX_FRAME_STACK
      frames = (max + 3).times.map { |i| manager.create_frame(name: :"f_#{i}") }
      frames.each { |f| manager.activate(f.id) }
      expect(manager.active_stack.size).to be <= max
    end
  end

  describe '#detect_context' do
    before do
      manager.create_frame(name: :coding, cues: %i[code debug test])
      manager.create_frame(name: :design, cues: %i[sketch wireframe review])
      manager.create_frame(name: :ops, cues: %i[deploy monitor])
    end

    it 'returns matching frames above relevance threshold' do
      results = manager.detect_context(%i[code test])
      expect(results.size).to be >= 1
      expect(results.first[:frame].name).to eq(:coding)
    end

    it 'returns empty when no cues match' do
      results = manager.detect_context(%i[sleep eat])
      expect(results).to be_empty
    end

    it 'sorts by relevance descending' do
      results = manager.detect_context(%i[code debug test])
      next unless results.size > 1

      expect(results.first[:relevance]).to be >= results.last[:relevance]
    end
  end

  describe '#auto_switch' do
    it 'switches to the best matching frame' do
      f1 = manager.create_frame(name: :coding, cues: %i[code debug test])
      manager.create_frame(name: :ops, cues: %i[deploy monitor])
      manager.activate(f1.id)

      result = manager.auto_switch(%i[deploy monitor alert])
      expect(result).not_to be_nil
      expect(result[:frame].name).to eq(:ops)
    end

    it 'returns nil when current frame is already the best match' do
      f1 = manager.create_frame(name: :coding, cues: %i[code debug test])
      manager.activate(f1.id)

      result = manager.auto_switch(%i[code debug])
      expect(result).to be_nil
    end

    it 'returns nil when no cues match' do
      manager.create_frame(name: :coding, cues: %i[code])
      result = manager.auto_switch(%i[sleep dream])
      expect(result).to be_nil
    end
  end

  describe '#find and #find_by_name' do
    it 'finds a frame by id' do
      frame = manager.create_frame(name: :work)
      expect(manager.find(frame.id)).to eq(frame)
    end

    it 'finds frames by name' do
      manager.create_frame(name: :work)
      manager.create_frame(name: :work)
      expect(manager.find_by_name(:work).size).to eq(2)
    end
  end

  describe '#in_domain' do
    it 'returns frames for the given domain' do
      manager.create_frame(name: :a, domain: :task)
      manager.create_frame(name: :b, domain: :social)
      manager.create_frame(name: :c, domain: :task)
      expect(manager.in_domain(:task).size).to eq(2)
    end
  end

  describe '#decay_all' do
    it 'decays all frames' do
      f = manager.create_frame(name: :work)
      initial = f.strength
      manager.decay_all
      expect(f.strength).to be < initial
    end

    it 'removes stale frames' do
      f = manager.create_frame(name: :old)
      100.times { f.decay }
      manager.decay_all
      expect(manager.frames).not_to include(f)
    end
  end

  describe '#remove' do
    it 'removes a frame by id' do
      f = manager.create_frame(name: :work)
      manager.remove(f.id)
      expect(manager.frames).to be_empty
    end

    it 'removes from active stack too' do
      f = manager.create_frame(name: :work)
      manager.activate(f.id)
      manager.remove(f.id)
      expect(manager.active_stack).to be_empty
    end
  end

  describe '#switch_cost_average' do
    it 'returns 0.0 with no switches' do
      expect(manager.switch_cost_average).to eq(0.0)
    end

    it 'computes the average switch cost' do
      f1 = manager.create_frame(name: :a)
      f2 = manager.create_frame(name: :b)
      manager.activate(f1.id)
      manager.activate(f2.id)
      expect(manager.switch_cost_average).to be > 0.0
    end
  end

  describe '#to_h' do
    it 'returns summary statistics' do
      manager.create_frame(name: :work, domain: :task)
      h = manager.to_h
      expect(h).to have_key(:frame_count)
      expect(h).to have_key(:active_frame)
      expect(h).to have_key(:stack_depth)
      expect(h).to have_key(:switch_count)
      expect(h).to have_key(:avg_switch_cost)
      expect(h).to have_key(:by_domain)
      expect(h[:frame_count]).to eq(1)
    end
  end
end
