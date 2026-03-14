# frozen_string_literal: true

module Legion
  module Extensions
    module Context
      module Helpers
        class ContextManager
          include Constants

          attr_reader :frames, :active_stack, :switch_history

          def initialize
            @frames         = []
            @active_stack   = []
            @switch_history = []
            @last_switch_at = nil
          end

          def create_frame(name:, domain: :general, cues: [])
            frame = Frame.new(name: name, domain: domain, cues: cues)
            @frames << frame
            trim_frames
            frame
          end

          def activate(frame_id)
            frame = find(frame_id)
            return nil unless frame

            previous = current_frame
            cost = 0.0

            if previous && previous.id != frame_id
              cost = compute_switch_cost(previous, frame)
              previous.deactivate
              record_switch(from: previous, to: frame, cost: cost)
            end

            @active_stack.reject! { |f| f.id == frame_id }
            @active_stack.push(frame)
            @active_stack.shift while @active_stack.size > MAX_FRAME_STACK
            frame.activate
            { frame: frame, switch_cost: cost }
          end

          def current_frame
            @active_stack.last
          end

          def detect_context(input_cues)
            scored = @frames.map { |f| [f, f.match_score(input_cues)] }
            scored.select! { |_, score| score >= RELEVANCE_THRESHOLD }
            scored.sort_by! { |_, score| -score }
            scored.map { |f, score| { frame: f, relevance: score } }
          end

          def auto_switch(input_cues)
            candidates = detect_context(input_cues)
            return nil if candidates.empty?

            best = candidates.first
            current = current_frame

            return nil if current && current.id == best[:frame].id

            activate(best[:frame].id)
          end

          def find(frame_id)
            @frames.find { |f| f.id == frame_id }
          end

          def find_by_name(name)
            @frames.select { |f| f.name == name }
          end

          def in_domain(domain)
            @frames.select { |f| f.domain == domain }
          end

          def decay_all
            @frames.each(&:decay)
            @frames.reject!(&:stale?)
            @active_stack.reject!(&:stale?)
          end

          def remove(frame_id)
            @frames.reject! { |f| f.id == frame_id }
            @active_stack.reject! { |f| f.id == frame_id }
          end

          def switch_cost_average
            return 0.0 if @switch_history.empty?

            @switch_history.sum { |s| s[:cost] }.to_f / @switch_history.size
          end

          def to_h
            {
              frame_count:     @frames.size,
              active_frame:    current_frame&.name,
              stack_depth:     @active_stack.size,
              switch_count:    @switch_history.size,
              avg_switch_cost: switch_cost_average.round(4),
              by_domain:       @frames.group_by(&:domain).transform_values(&:size)
            }
          end

          private

          def compute_switch_cost(from_frame, to_frame)
            base = SWITCH_COST
            familiarity_discount = to_frame.familiarity * 0.2
            domain_bonus = from_frame.domain == to_frame.domain ? 0.02 : 0.0
            cooldown_penalty = in_cooldown? ? 0.1 : 0.0
            (base - familiarity_discount - domain_bonus + cooldown_penalty).clamp(0.0, 1.0)
          end

          def in_cooldown?
            return false unless @last_switch_at

            (Time.now.utc - @last_switch_at) < SWITCH_COOLDOWN
          end

          def record_switch(from:, to:, cost:)
            @last_switch_at = Time.now.utc
            @switch_history << {
              from: from.name,
              to:   to.name,
              cost: cost,
              at:   @last_switch_at
            }
            @switch_history.shift while @switch_history.size > MAX_HISTORY
          end

          def trim_frames
            return unless @frames.size > MAX_FRAMES

            @frames.sort_by!(&:strength)
            @frames.shift(@frames.size - MAX_FRAMES)
          end
        end
      end
    end
  end
end
