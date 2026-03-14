# frozen_string_literal: true

RSpec.describe Legion::Extensions::DefaultModeNetwork::Helpers::WanderingThought do
  subject(:thought) do
    described_class.new(
      seed:              :identity,
      association_chain: %i[identity values purpose],
      domain:            :self,
      thought_type:      :self_referential,
      salience:          0.6
    )
  end

  describe '#initialize' do
    it 'assigns all fields' do
      expect(thought.seed).to eq(:identity)
      expect(thought.association_chain).to eq(%i[identity values purpose])
      expect(thought.domain).to eq(:self)
      expect(thought.thought_type).to eq(:self_referential)
      expect(thought.salience).to eq(0.6)
    end

    it 'generates a UUID id' do
      expect(thought.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'records created_at as a Time' do
      expect(thought.created_at).to be_a(Time)
    end

    it 'clamps salience to 0..1' do
      high = described_class.new(seed: :x, association_chain: [], domain: :d, thought_type: :wandering, salience: 5.0)
      low  = described_class.new(seed: :x, association_chain: [], domain: :d, thought_type: :wandering, salience: -1.0)
      expect(high.salience).to eq(1.0)
      expect(low.salience).to eq(0.0)
    end

    it 'coerces thought_type to symbol' do
      t = described_class.new(seed: :x, association_chain: [], domain: :d, thought_type: 'wandering')
      expect(t.thought_type).to eq(:wandering)
    end

    it 'wraps non-array association_chain in an array' do
      t = described_class.new(seed: :x, association_chain: :single, domain: :d, thought_type: :wandering)
      expect(t.association_chain).to eq([:single])
    end
  end

  describe '#boost_salience' do
    it 'increases salience by SALIENCE_ALPHA by default' do
      before = thought.salience
      thought.boost_salience
      expect(thought.salience).to be_within(0.001).of(before + described_module::SALIENCE_ALPHA)
    end

    it 'accepts a custom amount' do
      before = thought.salience
      thought.boost_salience(0.2)
      expect(thought.salience).to be_within(0.001).of(before + 0.2)
    end

    it 'caps at 1.0' do
      thought.salience = 0.99
      thought.boost_salience(0.5)
      expect(thought.salience).to eq(1.0)
    end
  end

  describe '#decay' do
    it 'reduces salience by THOUGHT_DECAY' do
      before = thought.salience
      thought.decay
      expect(thought.salience).to be_within(0.001).of(before - described_module::THOUGHT_DECAY)
    end

    it 'does not drop below THOUGHT_SALIENCE_FLOOR' do
      500.times { thought.decay }
      expect(thought.salience).to be >= described_module::THOUGHT_SALIENCE_FLOOR
    end
  end

  describe '#faded?' do
    it 'returns false for a strong thought' do
      expect(thought.faded?).to be false
    end

    it 'returns true at the salience floor' do
      thought.salience = described_module::THOUGHT_SALIENCE_FLOOR
      expect(thought.faded?).to be true
    end

    it 'returns false just above the floor' do
      thought.salience = described_module::THOUGHT_SALIENCE_FLOOR + 0.01
      expect(thought.faded?).to be false
    end
  end

  describe '#label' do
    it 'returns :significant for salience 0.7' do
      thought.salience = 0.7
      expect(thought.label).to eq(:significant)
    end

    it 'returns :breakthrough for salience 0.9' do
      thought.salience = 0.9
      expect(thought.label).to eq(:breakthrough)
    end

    it 'returns :fleeting for salience 0.1' do
      thought.salience = 0.1
      expect(thought.label).to eq(:fleeting)
    end

    it 'returns :notable for salience 0.5' do
      thought.salience = 0.5
      expect(thought.label).to eq(:notable)
    end

    it 'returns :passing for salience 0.3' do
      thought.salience = 0.3
      expect(thought.label).to eq(:passing)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = thought.to_h
      expect(h).to include(:id, :seed, :association_chain, :domain, :thought_type, :salience, :label, :created_at)
    end

    it 'includes the current label' do
      thought.salience = 0.9
      expect(thought.to_h[:label]).to eq(:breakthrough)
    end

    it 'rounds salience to 4 decimal places' do
      thought.salience = 0.123456789
      expect(thought.to_h[:salience]).to eq(0.1235)
    end
  end

  def described_module
    Legion::Extensions::DefaultModeNetwork::Helpers::Constants
  end
end
