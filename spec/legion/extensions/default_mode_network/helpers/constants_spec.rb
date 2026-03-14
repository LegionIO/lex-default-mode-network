# frozen_string_literal: true

RSpec.describe Legion::Extensions::DefaultModeNetwork::Helpers::Constants do
  subject(:mod) { Class.new { include Legion::Extensions::DefaultModeNetwork::Helpers::Constants } }

  describe 'idle thresholds' do
    it 'IDLE_THRESHOLD is 30' do
      expect(described_module::IDLE_THRESHOLD).to eq(30)
    end

    it 'DEEP_IDLE_THRESHOLD is 300' do
      expect(described_module::DEEP_IDLE_THRESHOLD).to eq(300)
    end
  end

  describe 'thought limits' do
    it 'MAX_WANDERING_THOUGHTS is 100' do
      expect(described_module::MAX_WANDERING_THOUGHTS).to eq(100)
    end

    it 'MAX_THOUGHT_HISTORY is 200' do
      expect(described_module::MAX_THOUGHT_HISTORY).to eq(200)
    end

    it 'MAX_ASSOCIATION_CHAIN is 5' do
      expect(described_module::MAX_ASSOCIATION_CHAIN).to eq(5)
    end
  end

  describe 'salience parameters' do
    it 'THOUGHT_SALIENCE_FLOOR is positive' do
      expect(described_module::THOUGHT_SALIENCE_FLOOR).to be > 0
    end

    it 'DEFAULT_SALIENCE is between floor and 1' do
      expect(described_module::DEFAULT_SALIENCE).to be_between(
        described_module::THOUGHT_SALIENCE_FLOOR, 1.0
      )
    end
  end

  describe 'ACTIVITY_LABELS' do
    it 'maps all four modes' do
      labels = described_module::ACTIVITY_LABELS
      expect(labels[:active]).to eq(:task_focused)
      expect(labels[:transitioning]).to eq(:shifting)
      expect(labels[:idle]).to eq(:daydreaming)
      expect(labels[:deep_idle]).to eq(:deep_reflection)
    end

    it 'is frozen' do
      expect(described_module::ACTIVITY_LABELS).to be_frozen
    end
  end

  describe 'SALIENCE_LABELS' do
    it 'maps ranges to quality labels' do
      labels = described_module::SALIENCE_LABELS
      expect(labels.values).to include(:breakthrough, :significant, :notable, :passing, :fleeting)
    end

    it 'covers 0.9 as breakthrough' do
      result = described_module::SALIENCE_LABELS.each { |range, lbl| break lbl if range.cover?(0.9) }
      expect(result).to eq(:breakthrough)
    end

    it 'covers 0.1 as fleeting' do
      result = described_module::SALIENCE_LABELS.each { |range, lbl| break lbl if range.cover?(0.1) }
      expect(result).to eq(:fleeting)
    end
  end

  def described_module
    Legion::Extensions::DefaultModeNetwork::Helpers::Constants
  end
end
