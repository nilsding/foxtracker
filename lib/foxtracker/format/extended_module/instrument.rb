# frozen_string_literal: true

require "dry-struct"

require "foxtracker/types"
require "foxtracker/format/extended_module/sample"

module Foxtracker
  module Format
    class ExtendedModule < Dry::Struct
      class Instrument < Dry::Struct
        # first part -- these attributes MUST be set on an instrument
        attribute :header_size, Types::Strict::Integer
        attribute :name, Types::Strict::String
        attribute :type, Types::Strict::Integer
        attribute :number_of_samples, Types::Strict::Integer

        # second part -- those are optional attributes
        attribute :sample_header_size, Types::Strict::Integer.meta(omittable: true)
        attribute :sample_keymap_assignments, Types::Strict::Array.of(Types::Strict::Integer)
          .constrained(size: 96).meta(omittable: true)
        # 48 bytes / 2 bytes = 24 words
        attribute :volume_envelope, Types::Strict::Array.of(Types::Strict::Integer)
          .constrained(size: 24).meta(omittable: true)
        attribute :panning_envelope, Types::Strict::Array.of(Types::Strict::Integer)
          .constrained(size: 24).meta(omittable: true)

        # envelope points
        attribute :number_of_volume_points, Types::Strict::Integer.meta(omittable: true)
        attribute :number_of_panning_points, Types::Strict::Integer.meta(omittable: true)
        attribute :volume_sustain_point, Types::Strict::Integer.meta(omittable: true)
        attribute :volume_loop_start_point, Types::Strict::Integer.meta(omittable: true)
        attribute :volume_loop_end_point, Types::Strict::Integer.meta(omittable: true)
        attribute :panning_sustain_point, Types::Strict::Integer.meta(omittable: true)
        attribute :panning_loop_start_point, Types::Strict::Integer.meta(omittable: true)
        attribute :panning_loop_end_point, Types::Strict::Integer.meta(omittable: true)
        attribute :volume_type, Types::Strict::String
          .enum("on" => 0, "sustain" => 1, "loop" => 2, "sustain_and_loop" => 3)
          .meta(omittable: true)
        attribute :panning_type, Types::Strict::String
          .enum("on" => 0, "sustain" => 1, "loop" => 2, "sustain_and_loop" => 3)
          .meta(omittable: true)
        attribute :vibrato_type, Types::Strict::Integer.meta(omittable: true)
        attribute :vibrato_sweep, Types::Strict::Integer.meta(omittable: true)
        attribute :vibrato_depth, Types::Strict::Integer.meta(omittable: true)
        attribute :vibrato_rate, Types::Strict::Integer.meta(omittable: true)
        attribute :volume_fadeout, Types::Strict::Integer.meta(omittable: true)
        attribute :reserved, Types::Strict::Array.of(Types::Strict::Integer).meta(omittable: true)

        attribute :samples, Types::Strict::Array.of(Sample).meta(omittable: true)
      end
    end
  end
end
