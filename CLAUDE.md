# lex-default-mode-network

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Default Mode Network (DMN) simulation for the LegionIO cognitive architecture. Models the brain's resting-state network that activates during idle time — self-referential thought, social replay, spontaneous planning, and associative wandering. When the agent has no active task, the DMN generates wandering thoughts to maintain internal activity and surface unresolved items for consolidation.

## Gem Info

- **Gem name**: `lex-default-mode-network`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::DefaultModeNetwork`
- **Location**: `extensions-agentic/lex-default-mode-network/`

## File Structure

```
lib/legion/extensions/default_mode_network/
  default_mode_network.rb       # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # IDLE_THRESHOLD, thought type probabilities, ACTIVITY_LABELS
    wandering_thought.rb        # WanderingThought value object with salience and decay
    dmn_engine.rb               # Engine: mode tracking, thought generation, decay
  actors/
    idle.rb                     # Every 30s actor calling update_dmn
  runners/
    default_mode_network.rb     # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `IDLE_THRESHOLD` | 30 | Seconds of inactivity before DMN activates |
| `DEEP_IDLE_THRESHOLD` | 300 | Seconds before deep idle (full DMN engagement) |
| `MAX_WANDERING_THOUGHTS` | 100 | Active thought cap |
| `MAX_THOUGHT_HISTORY` | 200 | Archived faded thought cap |
| `MAX_ASSOCIATION_CHAIN` | 5 | Max hops in an association chain |
| `THOUGHT_DECAY` | 0.01 | Salience lost per decay cycle |
| `THOUGHT_SALIENCE_FLOOR` | 0.05 | Threshold below which thoughts are archived |
| `SELF_REFERENTIAL_PROBABILITY` | 0.3 | Probability of self-referential thought |
| `SOCIAL_REPLAY_PROBABILITY` | 0.2 | Probability of social replay thought |
| `PLANNING_PROBABILITY` | 0.2 | Probability of spontaneous planning thought |
| `ACTIVITY_LABELS` | hash | `:active→:task_focused`, `:idle→:daydreaming`, `:deep_idle→:deep_reflection` |

## Runners

All methods in `Legion::Extensions::DefaultModeNetwork::Runners::DefaultModeNetwork`.

| Method | Key Args | Returns |
|---|---|---|
| `register_external_stimulus` | `source: nil` | `{ success:, previous_mode:, current_mode:, source: }` |
| `generate_idle_thought` | — | `{ success:, thought: }` |
| `trigger_self_reflection` | — | `{ success:, thought: }` |
| `trigger_social_replay` | `interaction: nil` | `{ success:, thought: }` |
| `trigger_spontaneous_plan` | `goal: nil` | `{ success:, thought: }` |
| `trigger_wandering` | `seed: nil` | `{ success:, thought: }` |
| `salient_thoughts` | `count: 5` | `{ success:, thoughts:, count: }` |
| `dmn_mode_status` | — | `{ success:, mode:, mode_label:, idle_duration:, thought_count: }` |
| `update_dmn` | — | Ticks mode, decays thoughts, generates idle thought if in idle/deep_idle |
| `dmn_stats` | — | `{ success:, stats: }` |

## Helpers

### `WanderingThought`
Value object. Attributes: `id`, `seed`, `association_chain` (array), `domain`, `thought_type`, `salience`, `created_at`. Methods: `boost_salience(amount)`, `decay`, `faded?`, `label` (from `SALIENCE_LABELS` range hash), `to_h`.

### `DmnEngine`
Mode state machine + thought store. Mode tracking: `register_stimulus` resets to `:active`, `tick_mode` computes mode from `idle_duration`. Thought generators: `generate_thought` (probabilistic dispatch), `self_reflect`, `social_replay`, `plan_spontaneously`, `wander`. Association chain building uses a hard-coded `derive_association` dictionary. Lifecycle: `salient_thoughts(count:)`, `decay_all` (returns count of faded thoughts), `thought_count`.

## Actor

`Actor::Idle` — `Every 30s`, calls `update_dmn`. Runs continuously. `run_now? false`, `use_runner? false`, `generate_task? false`.

## Integration Points

- `register_external_stimulus` should be called when lex-tick processes any external signal
- `salient_thoughts` provides content for lex-dream's consolidation phase
- `form_agenda` from thought content can feed lex-tick's idle agenda formation
- DMN mode status can modulate lex-emotion arousal (deep_idle = lower arousal)

## Development Notes

- Mode transition: active → transitioning → idle → deep_idle (one-way based on elapsed time; reset by stimulus)
- Thought type probabilities must sum to ≤ 1.0 (remaining 30% is `:wandering`)
- Association chains are deterministic (dictionary-based), not random
- Faded thoughts are archived to `@thought_history`, not deleted
