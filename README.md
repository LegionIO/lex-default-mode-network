# lex-default-mode-network

Default Mode Network simulation for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models the brain's resting-state network that activates during idle time. When the agent has no active task, the DMN generates wandering thoughts across four categories: self-reflection, social replay, spontaneous planning, and associative wandering. Tracks idle duration and transitions through activity modes.

After 30 seconds of no external stimuli: daydreaming mode. After 5 minutes: deep reflection mode.

## Usage

```ruby
client = Legion::Extensions::DefaultModeNetwork::Client.new

# Signal that an external event occurred (resets idle timer)
client.register_external_stimulus(source: :user_request)
# => { success: true, previous_mode: :idle, current_mode: :active }

# Check current mode
client.dmn_mode_status
# => { mode: :idle, mode_label: :daydreaming, idle_duration: 45.2, thought_count: 3 }

# Generate a thought explicitly
client.trigger_self_reflection
# => { success: true, thought: { seed: :values, association_chain: [:values, :purpose, :goals], salience: 0.6, ... } }

client.trigger_spontaneous_plan(goal: :pending_task)
client.trigger_social_replay(interaction: :recent_conversation)

# Get the most salient active thoughts
client.salient_thoughts(count: 5)

# Run the periodic tick (advance mode, decay thoughts, generate idle thought if idle)
client.update_dmn
# => { mode: :idle, faded_count: 1, thought_count: 8, new_thought: { ... } }
```

## Activity Modes

| Mode | Label | Trigger |
|---|---|---|
| `:active` | `:task_focused` | stimulus received |
| `:transitioning` | `:shifting` | brief transition |
| `:idle` | `:daydreaming` | 30s of no stimulus |
| `:deep_idle` | `:deep_reflection` | 300s of no stimulus |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
