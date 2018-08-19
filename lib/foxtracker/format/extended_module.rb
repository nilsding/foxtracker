# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/extended_module/pattern"
require "foxtracker/format/extended_module/instrument"

module Foxtracker
  module Format
    class ExtendedModule < Dry::Struct
      # Header
      attribute :title, Types::Strict::String
      attribute :tracker, Types::Strict::String
      attribute :version_number, Types::Strict::Integer
      attribute :header_size, Types::Strict::Integer
      attribute :song_length, Types::Strict::Integer.constrained(min_size: 1, max_size: 256)
      attribute :restart_position, Types::Strict::Integer
      attribute :number_of_channels, Types::Strict::Integer
      attribute :number_of_patterns, Types::Strict::Integer
      attribute :number_of_instruments, Types::Strict::Integer
      attribute :flags, Types::Strict::Integer
      attribute :default_tempo, Types::Strict::Integer
      attribute :default_bpm, Types::Strict::Integer
      attribute :pattern_order, Types::Strict::Array.of(Types::Strict::Integer)

      attribute :patterns, Types::Strict::Array.of(Pattern)
      attribute :instruments, Types::Strict::Array.of(Instrument)
    end
  end
end
