# frozen_string_literal: true

module Legion
  module Extensions
    module DefaultModeNetwork
      module Helpers
        module Constants
          # Idle time thresholds
          IDLE_THRESHOLD      = 30   # seconds before DMN activates
          DEEP_IDLE_THRESHOLD = 300  # seconds before deep idle mode

          # Thought storage limits
          MAX_WANDERING_THOUGHTS = 100
          MAX_THOUGHT_HISTORY    = 200
          MAX_ASSOCIATION_CHAIN  = 5 # max hops in a wandering chain

          # Salience parameters
          THOUGHT_SALIENCE_FLOOR = 0.05
          THOUGHT_DECAY          = 0.01
          DEFAULT_SALIENCE       = 0.3
          SALIENCE_ALPHA         = 0.1

          # Probabilistic thought-type selection (must sum to <= 1.0)
          SELF_REFERENTIAL_PROBABILITY = 0.3
          SOCIAL_REPLAY_PROBABILITY    = 0.2
          PLANNING_PROBABILITY         = 0.2
          WANDERING_PROBABILITY        = 0.3

          # Activity mode labels
          ACTIVITY_LABELS = {
            active:        :task_focused,
            transitioning: :shifting,
            idle:          :daydreaming,
            deep_idle:     :deep_reflection
          }.freeze

          # Salience quality labels — range-keyed hash
          SALIENCE_LABELS = {
            (0.8..)     => :breakthrough,
            (0.6...0.8) => :significant,
            (0.4...0.6) => :notable,
            (0.2...0.4) => :passing,
            (..0.2)     => :fleeting
          }.freeze
        end
      end
    end
  end
end
