# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Context
      module Helpers
        class Frame
          include Constants

          attr_reader :id, :name, :domain, :cues, :strength, :familiarity,
                      :created_at, :last_activated, :activation_count

          def initialize(name:, domain: :general, cues: [])
            @id               = SecureRandom.uuid
            @name             = name
            @domain           = domain
            @cues             = cues.first(MAX_CUES_PER_FRAME)
            @strength         = 1.0
            @familiarity      = DEFAULT_FAMILIARITY
            @created_at       = Time.now.utc
            @last_activated   = @created_at
            @activation_count = 0
          end

          def activate
            @last_activated = Time.now.utc
            @activation_count += 1
            @strength = [@strength + 0.1, 1.0].min
            update_familiarity(1.0)
          end

          def deactivate
            update_familiarity(0.0)
          end

          def decay
            @strength = [(@strength - FRAME_DECAY), 0.0].max
          end

          def match_score(input_cues)
            return 0.0 if @cues.empty? || input_cues.empty?

            overlap = (@cues & input_cues).size
            overlap.to_f / @cues.size
          end

          def add_cue(cue)
            return if @cues.include?(cue)

            @cues << cue
            @cues.shift if @cues.size > MAX_CUES_PER_FRAME
          end

          def remove_cue(cue)
            @cues.delete(cue)
          end

          def label
            FRAME_LABELS.each do |range, lbl|
              return lbl if range.cover?(@strength)
            end
            :fading
          end

          def stale?
            @strength < FRAME_STRENGTH_FLOOR
          end

          def to_h
            {
              id:               @id,
              name:             @name,
              domain:           @domain,
              strength:         @strength,
              familiarity:      @familiarity,
              label:            label,
              cues:             @cues.dup,
              activation_count: @activation_count,
              created_at:       @created_at,
              last_activated:   @last_activated
            }
          end

          private

          def update_familiarity(signal)
            @familiarity = ((FAMILIARITY_ALPHA * signal) + ((1.0 - FAMILIARITY_ALPHA) * @familiarity)).clamp(0.0, 1.0)
          end
        end
      end
    end
  end
end
