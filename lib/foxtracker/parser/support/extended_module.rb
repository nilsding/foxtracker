# frozen_string_literal: true

module Foxtracker
  module Parser
    module Support
      module ExtendedModule
        module_function

        # returns the sample looping type (:none, :forward, or :pingpong)
        def sample_looping_type(sample_type_byte)
          case sample_type_byte & 0b11
          when 0 then :none
          when 1 then :forward
          when 2 then :pingpong
          else
            raise "this should never happen(tm)"
          end
        end

        # returns the sample type (8 bit or 16 bit)
        def sample_type(sample_type_byte)
          ((sample_type_byte & 0b1000) >> 3).zero? ? 8 : 16
        end
      end
    end
  end
end
