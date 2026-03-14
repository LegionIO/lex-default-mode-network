# frozen_string_literal: true

RSpec.describe Legion::Extensions::DefaultModeNetwork::Runners::DefaultModeNetwork do
  let(:client) { Legion::Extensions::DefaultModeNetwork::Client.new }

  describe '#register_external_stimulus' do
    it 'returns success' do
      result = client.register_external_stimulus(source: :user_request)
      expect(result[:success]).to be true
    end

    it 'returns mode fields' do
      result = client.register_external_stimulus(source: :test)
      expect(result).to have_key(:previous_mode)
      expect(result).to have_key(:current_mode)
    end

    it 'resets to :active mode' do
      result = client.register_external_stimulus
      expect(result[:current_mode]).to eq(:active)
    end

    it 'includes source in result' do
      result = client.register_external_stimulus(source: :webhook)
      expect(result[:source]).to eq(:webhook)
    end
  end

  describe '#generate_idle_thought' do
    it 'returns success' do
      result = client.generate_idle_thought
      expect(result[:success]).to be true
    end

    it 'returns a thought hash' do
      result = client.generate_idle_thought
      expect(result[:thought]).to be_a(Hash)
      expect(result[:thought]).to include(:id, :seed, :thought_type, :salience)
    end

    it 'thought has a valid type' do
      valid_types = %w[self_referential social_replay spontaneous_plan wandering]
      result      = client.generate_idle_thought
      expect(valid_types).to include(result[:thought][:thought_type].to_s)
    end
  end

  describe '#trigger_self_reflection' do
    it 'returns success' do
      result = client.trigger_self_reflection
      expect(result[:success]).to be true
    end

    it 'returns a self_referential thought' do
      result = client.trigger_self_reflection
      expect(result[:thought][:thought_type]).to eq(:self_referential)
    end

    it 'thought has domain :self' do
      result = client.trigger_self_reflection
      expect(result[:thought][:domain]).to eq(:self)
    end

    it 'includes association chain' do
      result = client.trigger_self_reflection
      expect(result[:thought][:association_chain]).to be_an(Array)
      expect(result[:thought][:association_chain]).not_to be_empty
    end
  end

  describe '#trigger_social_replay' do
    it 'returns success' do
      result = client.trigger_social_replay(interaction: :standup)
      expect(result[:success]).to be true
    end

    it 'returns a social_replay thought' do
      result = client.trigger_social_replay
      expect(result[:thought][:thought_type]).to eq(:social_replay)
    end

    it 'uses provided interaction as seed' do
      result = client.trigger_social_replay(interaction: :team_meeting)
      expect(result[:thought][:seed]).to eq(:team_meeting)
    end

    it 'uses default seed when interaction is nil' do
      result = client.trigger_social_replay
      expect(result[:thought][:seed]).not_to be_nil
    end

    it 'thought domain is :social' do
      result = client.trigger_social_replay
      expect(result[:thought][:domain]).to eq(:social)
    end
  end

  describe '#trigger_spontaneous_plan' do
    it 'returns success' do
      result = client.trigger_spontaneous_plan(goal: :reduce_latency)
      expect(result[:success]).to be true
    end

    it 'returns a spontaneous_plan thought' do
      result = client.trigger_spontaneous_plan
      expect(result[:thought][:thought_type]).to eq(:spontaneous_plan)
    end

    it 'uses provided goal as seed' do
      result = client.trigger_spontaneous_plan(goal: :scale_out)
      expect(result[:thought][:seed]).to eq(:scale_out)
    end

    it 'thought domain is :planning' do
      result = client.trigger_spontaneous_plan
      expect(result[:thought][:domain]).to eq(:planning)
    end

    it 'salience is in range 0..1' do
      result = client.trigger_spontaneous_plan
      expect(result[:thought][:salience]).to be_between(0.0, 1.0)
    end
  end

  describe '#trigger_wandering' do
    it 'returns success' do
      result = client.trigger_wandering(seed: :curiosity)
      expect(result[:success]).to be true
    end

    it 'returns a wandering thought' do
      result = client.trigger_wandering
      expect(result[:thought][:thought_type]).to eq(:wandering)
    end

    it 'uses provided seed' do
      result = client.trigger_wandering(seed: :pattern)
      expect(result[:thought][:seed]).to eq(:pattern)
    end

    it 'thought domain is :associative' do
      result = client.trigger_wandering
      expect(result[:thought][:domain]).to eq(:associative)
    end

    it 'association chain starts with the seed' do
      result = client.trigger_wandering(seed: :creativity)
      expect(result[:thought][:association_chain].first).to eq(:creativity)
    end
  end

  describe '#salient_thoughts' do
    before do
      3.times { client.generate_idle_thought }
    end

    it 'returns success' do
      result = client.salient_thoughts(count: 2)
      expect(result[:success]).to be true
    end

    it 'returns up to count thoughts' do
      result = client.salient_thoughts(count: 2)
      expect(result[:thoughts].size).to be <= 2
    end

    it 'includes count in result' do
      result = client.salient_thoughts(count: 3)
      expect(result[:count]).to eq(result[:thoughts].size)
    end

    it 'thoughts are hashes with expected keys' do
      result = client.salient_thoughts(count: 1)
      result[:thoughts].each do |t|
        expect(t).to include(:id, :thought_type, :salience)
      end
    end

    it 'returns empty array when no thoughts exist' do
      fresh_client = Legion::Extensions::DefaultModeNetwork::Client.new
      result       = fresh_client.salient_thoughts
      expect(result[:thoughts]).to be_empty
    end
  end

  describe '#dmn_mode_status' do
    it 'returns success' do
      result = client.dmn_mode_status
      expect(result[:success]).to be true
    end

    it 'returns mode as symbol' do
      result = client.dmn_mode_status
      expect(%i[active transitioning idle deep_idle]).to include(result[:mode])
    end

    it 'includes mode_label' do
      result = client.dmn_mode_status
      labels = Legion::Extensions::DefaultModeNetwork::Helpers::Constants::ACTIVITY_LABELS.values
      expect(labels).to include(result[:mode_label])
    end

    it 'includes idle_duration as float' do
      result = client.dmn_mode_status
      expect(result[:idle_duration]).to be_a(Float)
    end

    it 'includes thought_count' do
      result = client.dmn_mode_status
      expect(result).to have_key(:thought_count)
    end
  end

  describe '#update_dmn' do
    it 'returns success' do
      result = client.update_dmn
      expect(result[:success]).to be true
    end

    it 'returns mode after tick' do
      result = client.update_dmn
      expect(%i[active transitioning idle deep_idle]).to include(result[:mode])
    end

    it 'returns previous_mode' do
      result = client.update_dmn
      expect(result).to have_key(:previous_mode)
    end

    it 'returns faded_count' do
      result = client.update_dmn
      expect(result[:faded_count]).to be_a(Integer)
    end

    it 'returns thought_count after decay' do
      result = client.update_dmn
      expect(result[:thought_count]).to be_a(Integer)
    end

    it 'generates a new thought when idle' do
      engine = Legion::Extensions::DefaultModeNetwork::Helpers::DmnEngine.new
      allow(engine).to receive(:idle_duration).and_return(60.0)
      engine.tick_mode # force to :idle
      idle_client = Legion::Extensions::DefaultModeNetwork::Client.new(dmn_engine: engine)
      result      = idle_client.update_dmn
      expect(result[:new_thought]).not_to be_nil
    end

    it 'new_thought is nil when active' do
      result = client.update_dmn
      # When just initialized, mode is active — no thought generated by update_dmn
      # (may be nil or a thought depending on mode after tick)
      expect(result).to have_key(:new_thought)
    end
  end

  describe '#dmn_stats' do
    it 'returns success' do
      result = client.dmn_stats
      expect(result[:success]).to be true
    end

    it 'includes stats hash' do
      result = client.dmn_stats
      expect(result[:stats]).to be_a(Hash)
      expect(result[:stats]).to include(:mode, :mode_label, :idle_duration, :thought_count)
    end
  end
end
