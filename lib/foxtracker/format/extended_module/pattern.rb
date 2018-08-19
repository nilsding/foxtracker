# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/extended_module/note"

module Foxtracker
  module Format
    class ExtendedModule < Dry::Struct
      class Pattern < Dry::Struct
        attribute :header_size, Types::Strict::Integer
        attribute :packing_type, Types::Strict::Integer
        attribute :number_of_rows, Types::Strict::Integer.constrained(min_size: 1, max_size: 256)
        attribute :packed_size, Types::Strict::Integer

        attribute :channels, Types::Strict::Array.of(Types::Strict::Array.of(Note))
      end
    end
  end
end
