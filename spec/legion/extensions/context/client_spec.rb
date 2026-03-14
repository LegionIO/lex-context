# frozen_string_literal: true

RSpec.describe Legion::Extensions::Context::Client do
  let(:client) { described_class.new }

  it 'can be instantiated' do
    expect(client).to be_a(described_class)
  end

  it 'includes all runner methods' do
    expect(client).to respond_to(:create_context)
    expect(client).to respond_to(:activate_context)
    expect(client).to respond_to(:detect_context)
    expect(client).to respond_to(:auto_switch)
    expect(client).to respond_to(:current_context)
    expect(client).to respond_to(:update_context)
    expect(client).to respond_to(:add_cue)
    expect(client).to respond_to(:frames_in_domain)
    expect(client).to respond_to(:remove_context)
    expect(client).to respond_to(:context_stats)
  end

  it 'exposes the context manager' do
    expect(client.context_manager).to be_a(Legion::Extensions::Context::Helpers::ContextManager)
  end

  describe 'full lifecycle' do
    it 'creates, activates, switches, and decays contexts' do
      # Create two contexts
      work = client.create_context(name: :work, domain: :task, cues: %i[code debug review])[:frame]
      client.create_context(name: :meeting, domain: :social, cues: %i[discuss plan agenda])[:frame]

      # Activate work
      client.activate_context(frame_id: work[:id])
      expect(client.current_context[:frame][:name]).to eq(:work)

      # Detect meeting context from cues
      detected = client.detect_context(input_cues: %i[discuss plan])
      expect(detected[:count]).to be >= 1

      # Auto-switch to meeting
      switched = client.auto_switch(input_cues: %i[discuss plan agenda])
      expect(switched[:switched]).to be true

      # Verify current context changed
      expect(client.current_context[:frame][:name]).to eq(:meeting)

      # Check stats
      stats = client.context_stats[:stats]
      expect(stats[:switch_count]).to eq(1)
      expect(stats[:frame_count]).to eq(2)

      # Tick decay
      client.update_context
      expect(client.context_stats[:stats][:frame_count]).to be >= 1
    end
  end
end
