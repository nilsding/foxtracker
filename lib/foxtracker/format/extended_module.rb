# frozen_string_literal: true

require "dry-struct"
require "foxtracker/types"

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

      class Note < Dry::Struct
        attribute :note, Types::Strict::Integer
        attribute :instrument, Types::Strict::Integer
        attribute :volume, Types::Strict::Integer
        attribute :effect_type, Types::Strict::Integer
        attribute :effect_param, Types::Strict::Integer
      end

      class Pattern < Dry::Struct
        attribute :header_size, Types::Strict::Integer
        attribute :packing_type, Types::Strict::Integer
        attribute :number_of_rows, Types::Strict::Integer.constrained(min_size: 1, max_size: 256)
        attribute :packed_size, Types::Strict::Integer

        attribute :channels, Types::Strict::Array.of(Types::Strict::Array.of(Note))
      end

      attribute :patterns, Types::Strict::Array.of(Pattern)

      class Sample < Dry::Struct
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

        # HACK: to remove :data from inspect output as sample data is really too spammy
        # https://github.com/dry-rb/dry-struct/blob/cb41a5a03/lib/dry/struct.rb#L178
        def inspect
          klass = self.class
          attrs = klass
                  .attribute_names
                  .reject { |key| key == :data }
                  .map { |key| " #{key}=#{@attributes[key].inspect}" }
                  .join
          "#<#{klass.name || klass.inspect}#{attrs}>"
        end
      end

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

      attribute :instruments, Types::Strict::Array.of(Instrument)
    end
  end
end
