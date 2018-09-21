# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/symphonie_module/pattern"
require "foxtracker/format/symphonie_module/instrument"

module Foxtracker
  module Format
    class SymphonieModule < Dry::Struct
      # Header
      attribute :version_number, Types::Strict::Integer
      attribute :number_of_channels, Types::Strict::Integer
      attribute :number_of_patterns, Types::Strict::Integer
      attribute :number_of_instruments, Types::Strict::Integer

      attribute :info_text, Types::Strict::String

      attribute :patterns, Types::Strict::Array.of(Pattern)
      attribute :instruments, Types::Strict::Array.of(Instrument)
    end
  end
end
