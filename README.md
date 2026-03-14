# lex-context

A LegionIO cognitive architecture extension for contextual framing and situation modeling. Maintains context frames that shape perception, memory retrieval, and action selection. Tracks context switches with measurable switch costs and familiarity-based discounts — switching to a familiar frame costs less than switching to an unfamiliar one.

## What It Does

Manages a registry of **frames** — each representing a situated context with a domain, a set of cues (tokens that activate the frame), and a strength score. An active frame stack (up to 10 deep) tracks the current cognitive situation.

- **Create frames** representing different operational contexts (coding, reviewing, planning)
- **Activate frames** explicitly or let `auto_switch` select the best match from input cues
- **Measure switch costs** — base 0.15 cost reduced by familiarity and same-domain bonuses, increased by rapid successive switches
- **Decay frames** over time — unused frames weaken and are eventually pruned from the registry

## Usage

```ruby
require 'lex-context'

client = Legion::Extensions::Context::Client.new

# Create context frames
coding = client.create_context(
  name:   'software_development',
  domain: :technical,
  cues:   [:code, :function, :test, :deploy, :bug]
)
# => { success: true, frame: { id: "uuid...", name: "software_development",
#      domain: :technical, strength: 1.0, familiarity: 0.3, label: :dominant, ... } }

review = client.create_context(
  name:   'code_review',
  domain: :technical,
  cues:   [:review, :pr, :feedback, :approve, :merge]
)

frame_id = coding[:frame][:id]

# Activate a frame explicitly
client.activate_context(frame_id: frame_id)
# => { success: true, frame: { ... }, switch_cost: 0.0 }

# Detect matching frames from input cues
client.detect_context(input_cues: [:review, :pr, :feedback])
# => { success: true, candidates: [{ frame: {...}, relevance: 0.6 }],
#      count: 1, best: { name: "code_review", relevance: 0.6 } }

# Automatically switch to the best-matching frame
client.auto_switch(input_cues: [:review, :pr])
# => { success: true, switched: true, frame: { ... }, switch_cost: 0.12 }

# Current active frame
client.current_context
# => { success: true, frame: { name: "code_review", ... } }

# Add a cue to an existing frame
client.add_cue(frame_id: frame_id, cue: :refactor)
# => { success: true, frame: { ... } }

# Periodic maintenance: decay all frames, remove stale ones
client.update_context
# => { success: true, frame_count: 2, active: "code_review" }

# Stats
client.context_stats
# => { success: true, stats: { frame_count: 2, active_frame: "code_review",
#      stack_depth: 1, switch_count: 1, avg_switch_cost: 0.12,
#      by_domain: { technical: 2 } } }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
