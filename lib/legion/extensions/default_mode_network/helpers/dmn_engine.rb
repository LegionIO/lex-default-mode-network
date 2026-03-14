# frozen_string_literal: true

module Legion
  module Extensions
    module DefaultModeNetwork
      module Helpers
        class DmnEngine
          include Constants

          attr_reader :mode, :last_stimulus_at, :thoughts, :thought_history, :wandering_seeds

          def initialize
            @mode              = :active
            @last_stimulus_at  = Time.now.utc
            @thoughts          = []
            @thought_history   = []
            @wandering_seeds   = []
          end

          # --- Stimulus / Mode ---

          def register_stimulus(source: nil)
            @last_stimulus_at = Time.now.utc
            previous          = @mode
            @mode             = :active
            { previous_mode: previous, current_mode: @mode, source: source, at: @last_stimulus_at }
          end

          def tick_mode
            elapsed = idle_duration
            previous = @mode

            @mode = if elapsed >= Constants::DEEP_IDLE_THRESHOLD
                      :deep_idle
                    elsif elapsed >= Constants::IDLE_THRESHOLD
                      :idle
                    elsif @mode == :active && elapsed.positive?
                      :transitioning
                    else
                      @mode
                    end

            { previous_mode: previous, current_mode: @mode, idle_duration: elapsed.round(2) }
          end

          def idle_duration
            Time.now.utc - @last_stimulus_at
          end

          # --- Thought Generation ---

          def generate_thought
            roll = rand
            thought = if roll < Constants::SELF_REFERENTIAL_PROBABILITY
                        self_reflect
                      elsif roll < Constants::SELF_REFERENTIAL_PROBABILITY + Constants::SOCIAL_REPLAY_PROBABILITY
                        social_replay(interaction: random_seed(:social))
                      elsif roll < Constants::SELF_REFERENTIAL_PROBABILITY +
                                   Constants::SOCIAL_REPLAY_PROBABILITY +
                                   Constants::PLANNING_PROBABILITY
                        plan_spontaneously(goal: random_seed(:goal))
                      else
                        wander(seed: random_seed(:concept))
                      end
            store_thought(thought)
            thought
          end

          def self_reflect(topic: nil)
            topics        = %i[identity values goals capabilities limitations purpose growth]
            chosen_topic  = topic || topics.sample
            chain         = build_association_chain(chosen_topic, Constants::MAX_ASSOCIATION_CHAIN)

            WanderingThought.new(
              seed:              chosen_topic,
              association_chain: chain,
              domain:            :self,
              thought_type:      :self_referential,
              salience:          rand(0.3..0.7)
            )
          end

          def social_replay(interaction: nil)
            seed  = interaction || :recent_interaction
            chain = build_association_chain(seed, Constants::MAX_ASSOCIATION_CHAIN)

            WanderingThought.new(
              seed:              seed,
              association_chain: chain,
              domain:            :social,
              thought_type:      :social_replay,
              salience:          rand(0.2..0.6)
            )
          end

          def plan_spontaneously(goal: nil)
            seed  = goal || :unresolved_objective
            chain = build_association_chain(seed, Constants::MAX_ASSOCIATION_CHAIN)

            WanderingThought.new(
              seed:              seed,
              association_chain: chain,
              domain:            :planning,
              thought_type:      :spontaneous_plan,
              salience:          rand(0.3..0.8)
            )
          end

          def wander(seed: nil)
            anchor = seed || random_seed(:concept)
            chain  = build_association_chain(anchor, Constants::MAX_ASSOCIATION_CHAIN)

            WanderingThought.new(
              seed:              anchor,
              association_chain: chain,
              domain:            :associative,
              thought_type:      :wandering,
              salience:          rand(0.1..0.5)
            )
          end

          # --- Retrieval ---

          def salient_thoughts(count: 5)
            @thoughts.sort_by { |t| -t.salience }.first(count)
          end

          def thoughts_of_type(type:)
            @thoughts.select { |t| t.thought_type == type.to_sym }
          end

          # --- Lifecycle ---

          def decay_all
            @thoughts.each(&:decay)
            faded = @thoughts.select(&:faded?)
            faded.each { |t| archive_thought(t) }
            @thoughts.reject!(&:faded?)
            faded.size
          end

          def thought_count
            @thoughts.size
          end

          def to_h
            {
              mode:             @mode,
              mode_label:       Constants::ACTIVITY_LABELS[@mode],
              idle_duration:    idle_duration.round(2),
              thought_count:    @thoughts.size,
              history_count:    @thought_history.size,
              last_stimulus_at: @last_stimulus_at
            }
          end

          private

          def store_thought(thought)
            @thoughts << thought
            prune_thoughts if @thoughts.size > Constants::MAX_WANDERING_THOUGHTS
            thought
          end

          def archive_thought(thought)
            @thought_history << thought.to_h
            @thought_history.shift while @thought_history.size > Constants::MAX_THOUGHT_HISTORY
          end

          def prune_thoughts
            @thoughts.sort_by! { |t| -t.salience }
            @thoughts.pop while @thoughts.size > Constants::MAX_WANDERING_THOUGHTS
          end

          def build_association_chain(seed, max_hops)
            chain = [seed]
            max_hops.times do
              next_concept = derive_association(chain.last)
              break if chain.include?(next_concept)

              chain << next_concept
            end
            chain
          end

          # Lightweight deterministic-ish association for standalone use
          def derive_association(concept)
            associations = {
              identity:      :values,
              values:        :purpose,
              purpose:       :goals,
              goals:         :capabilities,
              capabilities:  :limitations,
              limitations:   :growth,
              growth:        :identity,
              social:        :empathy,
              empathy:       :trust,
              trust:         :collaboration,
              collaboration: :outcome,
              outcome:       :reflection
            }
            associations.fetch(concept.to_sym, :"#{concept}_context")
          end

          def random_seed(category)
            pools = {
              social:  %i[recent_conversation last_request team_interaction feedback_given feedback_received],
              goal:    %i[pending_task unresolved_objective upcoming_deadline open_question improvement_opportunity],
              concept: %i[efficiency creativity curiosity uncertainty possibility connection meaning pattern]
            }
            pools.fetch(category, pools[:concept]).sample
          end
        end
      end
    end
  end
end
