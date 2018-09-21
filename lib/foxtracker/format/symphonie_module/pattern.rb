# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/symphonie_module/note"

module Foxtracker
  module Format
    class SymphonieModule < Dry::Struct
      class Pattern < Dry::Struct
        attribute :channels, Types::Strict::Array.of(Types::Strict::Array.of(Note))
      end
    end
  end
end
