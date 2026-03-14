# frozen_string_literal: true

module Legion
  module Extensions
    module Context
      module Runners
        module Context
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_context(name:, domain: :general, cues: [], **)
            frame = context_manager.create_frame(name: name, domain: domain, cues: cues)
            Legion::Logging.debug "[context] created frame=#{name} domain=#{domain} cues=#{cues.size}"
            { success: true, frame: frame.to_h }
          end

          def activate_context(frame_id:, **)
            result = context_manager.activate(frame_id)
            return { success: false, reason: :not_found } unless result

            frame = result[:frame]
            Legion::Logging.debug "[context] activated frame=#{frame.name} cost=#{result[:switch_cost].round(3)}"
            { success: true, frame: frame.to_h, switch_cost: result[:switch_cost] }
          end

          def detect_context(input_cues:, **)
            matches = context_manager.detect_context(input_cues)
            Legion::Logging.debug "[context] detect: #{matches.size} candidates for #{input_cues.size} cues"
            {
              success:    true,
              candidates: matches.map { |m| { frame: m[:frame].to_h, relevance: m[:relevance] } },
              count:      matches.size,
              best:       matches.first && { name: matches.first[:frame].name, relevance: matches.first[:relevance] }
            }
          end

          def auto_switch(input_cues:, **)
            result = context_manager.auto_switch(input_cues)
            return { success: true, switched: false, reason: :no_better_match } unless result

            frame = result[:frame]
            Legion::Logging.debug "[context] auto-switched to frame=#{frame.name} cost=#{result[:switch_cost].round(3)}"
            { success: true, switched: true, frame: frame.to_h, switch_cost: result[:switch_cost] }
          end

          def current_context(**)
            frame = context_manager.current_frame
            return { success: true, frame: nil } unless frame

            { success: true, frame: frame.to_h }
          end

          def update_context(**)
            context_manager.decay_all
            Legion::Logging.debug "[context] tick: frames=#{context_manager.frames.size} active=#{context_manager.current_frame&.name}"
            { success: true, frame_count: context_manager.frames.size, active: context_manager.current_frame&.name }
          end

          def add_cue(frame_id:, cue:, **)
            frame = context_manager.find(frame_id)
            return { success: false, reason: :not_found } unless frame

            frame.add_cue(cue)
            { success: true, frame: frame.to_h }
          end

          def frames_in_domain(domain:, **)
            frames = context_manager.in_domain(domain)
            { success: true, frames: frames.map(&:to_h), count: frames.size }
          end

          def remove_context(frame_id:, **)
            context_manager.remove(frame_id)
            { success: true }
          end

          def context_stats(**)
            { success: true, stats: context_manager.to_h }
          end

          private

          def context_manager
            @context_manager ||= Helpers::ContextManager.new
          end
        end
      end
    end
  end
end
