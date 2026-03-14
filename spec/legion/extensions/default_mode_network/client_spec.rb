# frozen_string_literal: true

RSpec.describe Legion::Extensions::DefaultModeNetwork::Client do
  subject(:client) { described_class.new }

  it 'includes Runners::DefaultModeNetwork' do
    expect(described_class.ancestors).to include(
      Legion::Extensions::DefaultModeNetwork::Runners::DefaultModeNetwork
    )
  end

  it 'responds to all runner methods' do
    %i[
      register_external_stimulus
      generate_idle_thought
      trigger_self_reflection
      trigger_social_replay
      trigger_spontaneous_plan
      trigger_wandering
      salient_thoughts
      dmn_mode_status
      update_dmn
      dmn_stats
    ].each do |method|
      expect(client).to respond_to(method)
    end
  end

  it 'accepts a custom dmn_engine' do
    engine = Legion::Extensions::DefaultModeNetwork::Helpers::DmnEngine.new
    c      = described_class.new(dmn_engine: engine)
    expect(c).to respond_to(:dmn_stats)
  end

  describe 'full DMN lifecycle scenario' do
    it 'goes from active through idle and generates thoughts' do
      # Start active — register stimulus
      stimulus_result = client.register_external_stimulus(source: :test_harness)
      expect(stimulus_result[:current_mode]).to eq(:active)

      # Explicitly trigger various thought types
      self_thought    = client.trigger_self_reflection
      social_thought  = client.trigger_social_replay(interaction: :pair_programming)
      plan_thought    = client.trigger_spontaneous_plan(goal: :optimize_query)
      wander_thought  = client.trigger_wandering(seed: :pattern)

      expect(self_thought[:thought][:thought_type]).to eq(:self_referential)
      expect(social_thought[:thought][:thought_type]).to eq(:social_replay)
      expect(plan_thought[:thought][:thought_type]).to eq(:spontaneous_plan)
      expect(wander_thought[:thought][:thought_type]).to eq(:wandering)

      # Check salient thoughts includes our injected thoughts
      salient = client.salient_thoughts(count: 10)
      expect(salient[:count]).to eq(4)

      # Run several update ticks — thoughts decay
      5.times { client.update_dmn }

      # Stats should still be coherent
      stats = client.dmn_stats
      expect(stats[:stats][:thought_count]).to be_a(Integer)

      # Mode status
      status = client.dmn_mode_status
      expect(status[:success]).to be true
      expect(status[:idle_duration]).to be >= 0
    end
  end
end
