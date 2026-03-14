# lex-context

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Models situated conceptualization — maintains context frames that shape perception, memory retrieval, and action selection. A frame bundles a domain, a set of cues (keywords or tokens that activate the frame), and a strength reflecting how recently and frequently it has been activated. The manager tracks a frame stack (up to 10 deep), computes switch costs when the active frame changes, and auto-selects the best frame given a set of input cues.

## Gem Info

- **Gem name**: `lex-context`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Context`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/context/
  version.rb
  helpers/
    constants.rb          # Frame limits, decay rate, switch cost constants, frame labels
    frame.rb              # Frame class — one situated context frame
    context_manager.rb    # ContextManager — frame registry with stack and switch tracking
  runners/
    context.rb            # Runner module — public API
  client.rb
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `MAX_FRAMES` | 50 | Hard cap; weakest frames removed when exceeded (sorted by strength, oldest discarded) |
| `MAX_FRAME_STACK` | 10 | Maximum depth of active frame stack |
| `FRAME_DECAY` | 0.02 | Strength reduction per `decay` call |
| `FRAME_STRENGTH_FLOOR` | 0.05 | Strength below this = stale (eligible for removal) |
| `SWITCH_COST` | 0.15 | Base cost to switch active frame |
| `SWITCH_COOLDOWN` | 5 | Seconds; rapid successive switches incur additional 0.1 penalty |
| `FAMILIARITY_ALPHA` | 0.12 | EMA alpha for familiarity updates |
| `DEFAULT_FAMILIARITY` | 0.3 | Initial familiarity for new frames |
| `RELEVANCE_THRESHOLD` | 0.2 | Minimum match score for `detect_context` candidates |
| `MAX_CUES_PER_FRAME` | 30 | Maximum cues per frame; oldest cue dropped on add when exceeded |
| `MAX_HISTORY` | 200 | Ring buffer for switch history |

Frame labels by strength: `0.8+` = `:dominant`, `0.5..0.8` = `:active`, `0.2..0.5` = `:background`, `< 0.2` = `:fading`

## Key Classes

### `Helpers::Frame`

One situated context frame.

- `activate` — increments `activation_count`, updates `last_activated`, increases strength by 0.1 (clamped at 1.0), updates familiarity toward 1.0 via EMA
- `deactivate` — updates familiarity toward 0.0 via EMA
- `decay` — decreases strength by `FRAME_DECAY`; does not remove the frame
- `match_score(input_cues)` — overlap of frame cues with input cues, divided by frame cue count; 0.0 if either is empty
- `add_cue(cue)` — appends cue (deduplication check); drops oldest cue when at `MAX_CUES_PER_FRAME`
- `remove_cue(cue)` — removes cue by value
- `stale?` — `strength < FRAME_STRENGTH_FLOOR` (0.05)
- `label` — range-based lookup from `FRAME_LABELS`
- Fields: `id` (UUID), `name`, `domain`, `cues` (array), `strength`, `familiarity`, `activation_count`, `created_at`, `last_activated`

### `Helpers::ContextManager`

Frame registry with switch tracking and active stack.

- `create_frame(name:, domain:, cues:)` — appends frame, trims by strength when at `MAX_FRAMES`
- `activate(frame_id)` — pushes frame to stack top; calls `deactivate` on previous frame; records switch with cost; removes existing position in stack before re-pushing; trims stack to `MAX_FRAME_STACK`; returns `{ frame:, switch_cost: }`
- `current_frame` — last element of `@active_stack`
- `detect_context(input_cues)` — returns scored frames above `RELEVANCE_THRESHOLD`, sorted descending
- `auto_switch(input_cues)` — calls `detect_context` and activates best match if different from current; returns nil if no candidates or already on best
- `find(frame_id)` / `find_by_name(name)` / `in_domain(domain)` — lookup methods
- `decay_all` — decays all frames; removes stale frames from both `@frames` and `@active_stack`
- `remove(frame_id)` — removes from both collections
- `switch_cost_average` — mean switch cost across all recorded switches
- Switch cost = base `SWITCH_COST` (0.15) - familiarity discount (familiarity * 0.2) - same-domain bonus (0.02) + cooldown penalty (0.1 if within 5 seconds of last switch)

## Runners

Module: `Legion::Extensions::Context::Runners::Context`

| Runner | Key Args | Returns |
|---|---|---|
| `create_context` | `name:`, `domain: :general`, `cues: []` | `{ success: true, frame: }` |
| `activate_context` | `frame_id:` | `{ success: true, frame:, switch_cost: }` or `{ success: false, reason: :not_found }` |
| `detect_context` | `input_cues:` | `{ success: true, candidates:, count:, best: }` |
| `auto_switch` | `input_cues:` | `{ success: true, switched: true, frame:, switch_cost: }` or `{ success: true, switched: false, reason: :no_better_match }` |
| `current_context` | — | `{ success: true, frame: }` (frame may be nil) |
| `update_context` | — | `{ success: true, frame_count:, active: }` (runs decay_all) |
| `add_cue` | `frame_id:`, `cue:` | `{ success: true, frame: }` or `{ success: false, reason: :not_found }` |
| `frames_in_domain` | `domain:` | `{ success: true, frames:, count: }` |
| `remove_context` | `frame_id:` | `{ success: true }` |
| `context_stats` | — | `{ success: true, stats: { frame_count:, active_frame:, stack_depth:, switch_count:, avg_switch_cost:, by_domain: } }` |

## Integration Points

- `update_context` should be called periodically (each tick) to apply frame decay and remove stale frames
- `detect_context` and `auto_switch` connect to `lex-tick`'s sensory processing phase — input cues from perception select the appropriate situational frame
- Active frame shapes which memory traces are retrieved (context-dependent memory) and which actions are appropriate
- `switch_cost` can feed into `lex-emotion` as a stress signal — high context-switching rate indicates cognitive load
- Pairs with `lex-memory`: memory retrieval should be filtered or weighted by the current frame's domain

## Development Notes

- `trim_frames` when at `MAX_FRAMES` sorts by strength ascending and drops from the front — weakest frames removed, not oldest by insertion
- `auto_switch` returns nil when there are no candidates or when the current frame is already the best match; the runner translates nil to `{ switched: false, reason: :no_better_match }`
- `deactivate` updates familiarity toward 0.0, not to 0.0 — it is an EMA step, not a reset
- Stack trim removes the oldest entries (shift) when depth exceeds `MAX_FRAME_STACK` after a push
- `frame_id:` in `activate_context` is a UUID string — not the frame name
- `decay_all` removes stale frames from both `@frames` array and `@active_stack` array using `reject!`
