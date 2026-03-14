# frozen_string_literal: true

module Legion
  module Extensions
    module Context
      module Helpers
        module Constants
          MAX_FRAMES           = 50
          MAX_FRAME_STACK      = 10
          FRAME_DECAY          = 0.02
          FRAME_STRENGTH_FLOOR = 0.05
          SWITCH_COST          = 0.15
          SWITCH_COOLDOWN      = 5
          FAMILIARITY_ALPHA    = 0.12
          DEFAULT_FAMILIARITY  = 0.3
          RELEVANCE_THRESHOLD  = 0.2
          MAX_CUES_PER_FRAME   = 30
          MAX_HISTORY          = 200

          FRAME_LABELS = {
            (0.8..)     => :dominant,
            (0.5...0.8) => :active,
            (0.2...0.5) => :background,
            (..0.2)     => :fading
          }.freeze
        end
      end
    end
  end
end
