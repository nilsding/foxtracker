# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/support/dry_types_unspect"

module Foxtracker
  module Format
    class SymphonieModule < Dry::Struct
      class Instrument < Dry::Struct
        include Foxtracker::Format::Support::DryTypesUnspect.new(:data)

        attribute :name, Types::Strict::String.optional

        attribute :instrument_type,   Types::Strict::Integer.optional
        attribute :loop_start,        Types::Strict::Integer.optional
        attribute :loop_length,       Types::Strict::Integer.optional
        attribute :loop_number,       Types::Strict::Integer.optional
        attribute :multi,             Types::Strict::Integer.optional
        attribute :auto_maximize,     Types::Strict::Integer.optional
        attribute :volume,            Types::Strict::Integer.optional
        attribute :relation,          Types::Strict::Integer.optional
        attribute :child_number,      Types::Strict::Integer.optional
        attribute :sample_type,       Types::Strict::Integer.optional
        attribute :finetune,          Types::Strict::Integer.optional
        attribute :tune,              Types::Strict::Integer.optional
        attribute :linesample_flags,  Types::Strict::Integer.optional
        attribute :filter,            Types::Strict::Integer.optional
        attribute :playflag,          Types::Strict::Integer.optional
        attribute :downsample,        Types::Strict::Integer.optional
        attribute :reso,              Types::Strict::Integer.optional
        attribute :loadflags,         Types::Strict::Integer.optional
        attribute :info,              Types::Strict::Integer.optional
        attribute :range_start,       Types::Strict::Integer.optional
        attribute :range_length,      Types::Strict::Integer.optional
        attribute :loop_start_low,    Types::Strict::Integer.optional
        attribute :loop_length_low,   Types::Strict::Integer.optional

        attribute :reso_filter_flags, Types::Strict::Integer.optional
        attribute :reso_filter_numb,  Types::Strict::Integer.optional
        attribute :reso_filter,       Types::Strict::Integer.optional

        attribute :vfade_status,      Types::Strict::Integer.optional
        attribute :vfade_start,       Types::Strict::Integer.optional
        attribute :vfade_end,         Types::Strict::Integer.optional

        attribute :data, Types::Strict::Array.of(Types::Strict::Integer).optional.meta(omittable: true)

        def empty?
          name.nil? && data.nil?
        end
      end
    end
  end
end
