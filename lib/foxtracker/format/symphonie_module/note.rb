# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"

module Foxtracker
  module Format
    class SymphonieModule < Dry::Struct
      class Note < Dry::Struct
        attribute :type, Types::Strict::Symbol | Types::Strict::Integer
        attribute :empty?, Types::Strict::Bool
        attribute :note, Types::Strict::Integer
        attribute :instrument, Types::Strict::Integer
        attribute :volume, Types::Strict::Integer
        attribute :volume_fx, Types::Strict::Symbol.optional
        attribute :note_fx, Types::Strict::Symbol.optional
      end
    end
  end
end
