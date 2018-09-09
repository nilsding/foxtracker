# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/support/dry_types_unspect"

module Foxtracker
  module Format
    class ExtendedModule < Dry::Struct
      class Sample < Dry::Struct
        include Foxtracker::Format::Support::DryTypesUnspect.new(:data)

        attribute :sample_length, Types::Strict::Integer
        attribute :sample_loop_start, Types::Strict::Integer
        attribute :sample_loop_length, Types::Strict::Integer

        attribute :volume, Types::Strict::Integer
        attribute :finetune, Types::Strict::Integer
        attribute :type, Types::Strict::Integer
        attribute :panning, Types::Strict::Integer
        attribute :relative_note_number, Types::Strict::Integer
        attribute :packing_type, Types::Strict::Integer # Types::Strict::String.enum("delta" => 0, "adpcm" => 0xAD)
        attribute :name, Types::Strict::String

        # attribute :raw_data, Types::Strict::String
        attribute :data, Types::Strict::Array.of(Types::Strict::Integer)

        # returns the sample looping type (:none, :forward, or :pingpong)
        def looping_type
          ExtendedModule::Helpers.sample_looping_type(type)
        end

        # returns the sample type (8 bit or 16 bit)
        def sample_type
          ExtendedModule::Helpers.sample_type(type)
        end

        # returns if this sample is to be looped
        def looping?
          !sample_loop_length.zero?
        end
      end
    end
  end
end
