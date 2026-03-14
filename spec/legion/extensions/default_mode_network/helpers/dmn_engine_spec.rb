# frozen_string_literal: true

RSpec.describe Legion::Extensions::DefaultModeNetwork::Helpers::DmnEngine do
  subject(:engine) { described_class.new }

  let(:const) { Legion::Extensions::DefaultModeNetwork::Helpers::Constants }

  describe '#initialize' do
    it 'starts in :active mode' do
      expect(engine.mode).to eq(:active)
    end

    it 'has an empty thought list' do
      expect(engine.thoughts).to be_empty
    end

    it 'has an empty thought history' do
      expect(engine.thought_history).to be_empty
    end

    it 'records last_stimulus_at as recent Time' do
      expect(engine.last_stimulus_at).to be_a(Time)
      expect(Time.now.utc - engine.last_stimulus_at).to be < 1
    end
  end

  describe '#register_stimulus' do
    it 'resets idle timer and returns mode info' do
      result = engine.register_stimulus(source: :api_call)
      expect(result[:current_mode]).to eq(:active)
      expect(result[:source]).to eq(:api_call)
      expect(result).to have_key(:previous_mode)
    end

    it 'switches mode back to active' do
      allow(engine).to receive(:idle_duration).and_return(60.0)
      engine.tick_mode
      engine.register_stimulus
      expect(engine.mode).to eq(:active)
    end

    it 'updates last_stimulus_at' do
      before = engine.last_stimulus_at
      sleep(0.01)
      engine.register_stimulus
      expect(engine.last_stimulus_at).to be > before
    end
  end

  describe '#tick_mode' do
    it 'remains active when recently stimulated' do
      result = engine.tick_mode
      # idle_duration is near 0, mode stays active or becomes transitioning
      expect(%i[active transitioning]).to include(result[:current_mode])
    end

    it 'transitions to :idle after IDLE_THRESHOLD seconds' do
      allow(engine).to receive(:idle_duration).and_return(const::IDLE_THRESHOLD.to_f + 1)
      result = engine.tick_mode
      expect(result[:current_mode]).to eq(:idle)
    end

    it 'transitions to :deep_idle after DEEP_IDLE_THRESHOLD seconds' do
      allow(engine).to receive(:idle_duration).and_return(const::DEEP_IDLE_THRESHOLD.to_f + 1)
      result = engine.tick_mode
      expect(result[:current_mode]).to eq(:deep_idle)
    end

    it 'returns previous and current mode' do
      result = engine.tick_mode
      expect(result).to have_key(:previous_mode)
      expect(result).to have_key(:current_mode)
    end

    it 'returns idle_duration in result' do
      result = engine.tick_mode
      expect(result[:idle_duration]).to be_a(Float)
    end
  end

  describe '#idle_duration' do
    it 'returns elapsed seconds since last stimulus' do
      expect(engine.idle_duration).to be >= 0
      expect(engine.idle_duration).to be < 5
    end
  end

  describe '#generate_thought' do
    it 'returns a WanderingThought' do
      thought = engine.generate_thought
      expect(thought).to be_a(Legion::Extensions::DefaultModeNetwork::Helpers::WanderingThought)
    end

    it 'stores the generated thought' do
      engine.generate_thought
      expect(engine.thought_count).to eq(1)
    end

    it 'increments thought count each call' do
      3.times { engine.generate_thought }
      expect(engine.thought_count).to eq(3)
    end

    it 'generates valid thought types' do
      valid_types = %i[self_referential social_replay spontaneous_plan wandering]
      10.times do
        t = engine.generate_thought
        expect(valid_types).to include(t.thought_type)
      end
    end
  end

  describe '#self_reflect' do
    it 'creates a self_referential thought' do
      thought = engine.self_reflect
      expect(thought.thought_type).to eq(:self_referential)
    end

    it 'sets domain to :self' do
      expect(engine.self_reflect.domain).to eq(:self)
    end

    it 'builds a non-empty association chain' do
      expect(engine.self_reflect.association_chain).not_to be_empty
    end

    it 'accepts a custom topic' do
      thought = engine.self_reflect(topic: :values)
      expect(thought.seed).to eq(:values)
    end

    it 'has positive salience' do
      expect(engine.self_reflect.salience).to be > 0
    end
  end

  describe '#social_replay' do
    it 'creates a social_replay thought' do
      thought = engine.social_replay(interaction: :recent_chat)
      expect(thought.thought_type).to eq(:social_replay)
    end

    it 'sets domain to :social' do
      expect(engine.social_replay.domain).to eq(:social)
    end

    it 'uses provided interaction as seed' do
      thought = engine.social_replay(interaction: :team_standup)
      expect(thought.seed).to eq(:team_standup)
    end

    it 'uses a default seed when interaction is nil' do
      thought = engine.social_replay
      expect(thought.seed).not_to be_nil
    end
  end

  describe '#plan_spontaneously' do
    it 'creates a spontaneous_plan thought' do
      thought = engine.plan_spontaneously(goal: :improve_latency)
      expect(thought.thought_type).to eq(:spontaneous_plan)
    end

    it 'sets domain to :planning' do
      expect(engine.plan_spontaneously.domain).to eq(:planning)
    end

    it 'uses provided goal as seed' do
      thought = engine.plan_spontaneously(goal: :reduce_errors)
      expect(thought.seed).to eq(:reduce_errors)
    end

    it 'generates higher salience than wandering (on average)' do
      plans   = 20.times.map { engine.plan_spontaneously }
      wanders = 20.times.map { engine.wander }
      expect(plans.sum(&:salience) / plans.size).to be > wanders.sum(&:salience) / wanders.size
    end
  end

  describe '#wander' do
    it 'creates a wandering thought' do
      thought = engine.wander(seed: :curiosity)
      expect(thought.thought_type).to eq(:wandering)
    end

    it 'sets domain to :associative' do
      expect(engine.wander.domain).to eq(:associative)
    end

    it 'uses provided seed' do
      thought = engine.wander(seed: :efficiency)
      expect(thought.seed).to eq(:efficiency)
    end

    it 'builds an association chain with the seed as first element' do
      thought = engine.wander(seed: :pattern)
      expect(thought.association_chain.first).to eq(:pattern)
    end

    it 'chain does not exceed MAX_ASSOCIATION_CHAIN' do
      thought = engine.wander(seed: :root)
      expect(thought.association_chain.size).to be <= const::MAX_ASSOCIATION_CHAIN + 1
    end
  end

  describe '#salient_thoughts' do
    before do
      engine.wander(seed: :a).tap { |t| t.salience = 0.8 }.tap { |t| engine.send(:store_thought, t) }
      engine.wander(seed: :b).tap { |t| t.salience = 0.3 }.tap { |t| engine.send(:store_thought, t) }
      engine.wander(seed: :c).tap { |t| t.salience = 0.9 }.tap { |t| engine.send(:store_thought, t) }
    end

    it 'returns thoughts sorted by descending salience' do
      thoughts = engine.salient_thoughts(count: 3)
      saliences = thoughts.map(&:salience)
      expect(saliences).to eq(saliences.sort.reverse)
    end

    it 'limits results by count' do
      expect(engine.salient_thoughts(count: 2).size).to eq(2)
    end

    it 'returns top thought with highest salience' do
      expect(engine.salient_thoughts(count: 1).first.seed).to eq(:c)
    end
  end

  describe '#thoughts_of_type' do
    before do
      engine.self_reflect.tap { |t| engine.send(:store_thought, t) }
      engine.social_replay.tap { |t| engine.send(:store_thought, t) }
      engine.wander.tap { |t| engine.send(:store_thought, t) }
    end

    it 'filters by thought_type' do
      results = engine.thoughts_of_type(type: :self_referential)
      expect(results.all? { |t| t.thought_type == :self_referential }).to be true
    end

    it 'returns empty array for unknown type' do
      expect(engine.thoughts_of_type(type: :unknown_type)).to be_empty
    end

    it 'accepts string type and coerces to symbol' do
      results = engine.thoughts_of_type(type: 'wandering')
      expect(results).not_to be_empty
    end
  end

  describe '#decay_all' do
    it 'decays all stored thoughts' do
      3.times { engine.generate_thought }
      before_saliences = engine.thoughts.map(&:salience).dup
      engine.decay_all
      # All thoughts should have lower or equal salience
      engine.thoughts.zip(before_saliences).each do |t, b|
        expect(t.salience).to be <= b
      end
    end

    it 'prunes thoughts that fade below floor' do
      thought = engine.wander(seed: :test)
      thought.salience = const::THOUGHT_SALIENCE_FLOOR + 0.001
      engine.send(:store_thought, thought)
      engine.decay_all
      expect(engine.thoughts).not_to include(thought)
    end

    it 'archives faded thoughts in thought_history' do
      thought = engine.wander(seed: :archive_me)
      thought.salience = const::THOUGHT_SALIENCE_FLOOR + 0.001
      engine.send(:store_thought, thought)
      engine.decay_all
      ids = engine.thought_history.map { |h| h[:id] }
      expect(ids).to include(thought.id)
    end

    it 'returns the count of faded thoughts removed' do
      thought = engine.wander(seed: :doomed)
      thought.salience = const::THOUGHT_SALIENCE_FLOOR + 0.001
      engine.send(:store_thought, thought)
      removed = engine.decay_all
      expect(removed).to eq(1)
    end
  end

  describe '#thought_count' do
    it 'returns 0 initially' do
      expect(engine.thought_count).to eq(0)
    end

    it 'increments with each stored thought' do
      5.times { engine.generate_thought }
      expect(engine.thought_count).to eq(5)
    end
  end

  describe 'thought pruning' do
    it 'does not exceed MAX_WANDERING_THOUGHTS' do
      (const::MAX_WANDERING_THOUGHTS + 10).times { engine.generate_thought }
      expect(engine.thought_count).to be <= const::MAX_WANDERING_THOUGHTS
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = engine.to_h
      expect(h).to include(:mode, :mode_label, :idle_duration, :thought_count, :history_count, :last_stimulus_at)
    end

    it 'includes the mode label from ACTIVITY_LABELS' do
      h = engine.to_h
      expect(const::ACTIVITY_LABELS.values).to include(h[:mode_label])
    end

    it 'reflects current thought count' do
      3.times { engine.generate_thought }
      expect(engine.to_h[:thought_count]).to eq(3)
    end
  end
end
