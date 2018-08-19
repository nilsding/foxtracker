# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"

module Foxtracker
  module Format
    class ExtendedModule < Dry::Struct
      class Note < Dry::Struct
        attribute :note, Types::Strict::Integer
        attribute :instrument, Types::Strict::Integer
        attribute :volume, Types::Strict::Integer
        attribute :effect_type, Types::Strict::Integer
        attribute :effect_param, Types::Strict::Integer
      end
    end
  end
end
