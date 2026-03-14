# frozen_string_literal: true

module Legion
  module Extensions
    module DefaultModeNetwork
      module Helpers
        class WanderingThought
          include Constants

          attr_reader :id, :seed, :association_chain, :domain, :thought_type, :created_at
          attr_accessor :salience

          def initialize(seed:, association_chain:, domain:, thought_type:, salience: Constants::DEFAULT_SALIENCE)
            @id               = SecureRandom.uuid
            @seed             = seed
            @association_chain = Array(association_chain)
            @domain           = domain
            @thought_type     = thought_type.to_sym
            @salience         = salience.to_f.clamp(0.0, 1.0)
            @created_at       = Time.now.utc
          end

          def boost_salience(amount = Constants::SALIENCE_ALPHA)
            @salience = [@salience + amount.to_f, 1.0].min
          end

          def decay
            @salience = [@salience - Constants::THOUGHT_DECAY, Constants::THOUGHT_SALIENCE_FLOOR].max
          end

          def faded?
            @salience <= Constants::THOUGHT_SALIENCE_FLOOR
          end

          def label
            Constants::SALIENCE_LABELS.each { |range, lbl| return lbl if range.cover?(@salience) }
            :fleeting
          end

          def to_h
            {
              id:                @id,
              seed:              @seed,
              association_chain: @association_chain,
              domain:            @domain,
              thought_type:      @thought_type,
              salience:          @salience.round(4),
              label:             label,
              created_at:        @created_at
            }
          end
        end
      end
    end
  end
end
