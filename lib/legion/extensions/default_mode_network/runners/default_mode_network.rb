# frozen_string_literal: true

module Legion
  module Extensions
    module DefaultModeNetwork
      module Runners
        module DefaultModeNetwork
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def register_external_stimulus(source: nil, **)
            Legion::Logging.debug "[dmn] register_stimulus: source=#{source}"
            result = dmn_engine.register_stimulus(source: source)
            {
              success:       true,
              previous_mode: result[:previous_mode],
              current_mode:  result[:current_mode],
              source:        result[:source]
            }
          end

          def generate_idle_thought(**)
            Legion::Logging.debug "[dmn] generate_idle_thought: mode=#{dmn_engine.mode}"
            thought = dmn_engine.generate_thought
            Legion::Logging.debug "[dmn] thought_generated: type=#{thought.thought_type} salience=#{thought.salience.round(2)} label=#{thought.label}"
            { success: true, thought: thought.to_h }
          end

          def trigger_self_reflection(**)
            Legion::Logging.debug '[dmn] trigger_self_reflection'
            thought = dmn_engine.self_reflect
            dmn_engine.send(:store_thought, thought)
            Legion::Logging.debug "[dmn] self_reflect: topic=#{thought.seed} salience=#{thought.salience.round(2)}"
            { success: true, thought: thought.to_h }
          end

          def trigger_social_replay(interaction: nil, **)
            Legion::Logging.debug "[dmn] trigger_social_replay: interaction=#{interaction}"
            thought = dmn_engine.social_replay(interaction: interaction)
            dmn_engine.send(:store_thought, thought)
            Legion::Logging.debug "[dmn] social_replay: seed=#{thought.seed} salience=#{thought.salience.round(2)}"
            { success: true, thought: thought.to_h }
          end

          def trigger_spontaneous_plan(goal: nil, **)
            Legion::Logging.debug "[dmn] trigger_spontaneous_plan: goal=#{goal}"
            thought = dmn_engine.plan_spontaneously(goal: goal)
            dmn_engine.send(:store_thought, thought)
            Legion::Logging.debug "[dmn] spontaneous_plan: goal=#{thought.seed} salience=#{thought.salience.round(2)}"
            { success: true, thought: thought.to_h }
          end

          def trigger_wandering(seed: nil, **)
            Legion::Logging.debug "[dmn] trigger_wandering: seed=#{seed}"
            thought = dmn_engine.wander(seed: seed)
            dmn_engine.send(:store_thought, thought)
            Legion::Logging.debug "[dmn] wandering: seed=#{thought.seed} chain_length=#{thought.association_chain.size}"
            { success: true, thought: thought.to_h }
          end

          def salient_thoughts(count: 5, **)
            count = count.to_i
            Legion::Logging.debug "[dmn] salient_thoughts: count=#{count}"
            thoughts = dmn_engine.salient_thoughts(count: count)
            { success: true, thoughts: thoughts.map(&:to_h), count: thoughts.size }
          end

          def dmn_mode_status(**)
            Legion::Logging.debug "[dmn] dmn_mode_status: mode=#{dmn_engine.mode}"
            mode        = dmn_engine.mode
            mode_label  = Helpers::Constants::ACTIVITY_LABELS[mode]
            idle_secs   = dmn_engine.idle_duration.round(2)
            {
              success:       true,
              mode:          mode,
              mode_label:    mode_label,
              idle_duration: idle_secs,
              thought_count: dmn_engine.thought_count
            }
          end

          def update_dmn(**)
            Legion::Logging.debug '[dmn] update_dmn: tick'
            tick_result   = dmn_engine.tick_mode
            faded_count   = dmn_engine.decay_all
            thought       = nil

            if %i[idle deep_idle].include?(dmn_engine.mode)
              thought = dmn_engine.generate_thought
              Legion::Logging.debug "[dmn] idle_thought: type=#{thought.thought_type} salience=#{thought.salience.round(2)}"
            end

            Legion::Logging.debug "[dmn] update_dmn: mode=#{tick_result[:current_mode]} faded=#{faded_count} thoughts=#{dmn_engine.thought_count}"
            {
              success:       true,
              mode:          tick_result[:current_mode],
              previous_mode: tick_result[:previous_mode],
              faded_count:   faded_count,
              thought_count: dmn_engine.thought_count,
              new_thought:   thought&.to_h
            }
          end

          def dmn_stats(**)
            Legion::Logging.debug '[dmn] dmn_stats'
            { success: true, stats: dmn_engine.to_h }
          end

          private

          def dmn_engine
            @dmn_engine ||= Helpers::DmnEngine.new
          end
        end
      end
    end
  end
end
