# frozen_string_literal: true

require "dry-types"
require "dry-struct"

module Foxtracker
  class Application
    def initialize(argv)
      @filename = argv.first
    end

    def run
      xm_contents = IO.binread(@filename)
      xm = ExtendedModule.parse(xm_contents)
      require "pp"
      pp xm
    ensure
      binding.irb
    end
  end

  class Types
    include Dry::Types.module
    
  end

  class ExtendedModule < Dry::Struct
    module Helpers
      module_function

      # returns the sample looping type (:none, :forward, or :pingpong)
      def sample_looping_type(sample_type_byte)
        case sample_type_byte & 0b11
        when 0 then :none
        when 1 then :forward
        when 2 then :pingpong
        else
          raise "this should never happen(tm)"
        end
      end

      # returns the sample type (8 bit or 16 bit)
      def sample_type(sample_type_byte)
        ((sample_type_byte & 0b1000) >> 3).zero? ? 8 : 16
      end
    end

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

    class Pattern < Dry::Struct
      attribute :header_size, Types::Strict::Integer
      attribute :packing_type, Types::Strict::Integer
      attribute :number_of_rows, Types::Strict::Integer.constrained(min_size: 1, max_size: 256)
      attribute :packed_size, Types::Strict::Integer
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

      # hack to remove :data from inspect output as sample data is really too spammy
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

    def self.parse(bin)
      bin = -bin
      args = {}
      offset = 0

      ##########
      # header #
      ##########
      raise "not an XM module" unless bin[offset...(offset += 17)].casecmp("Extended module: ").zero?

      args[:title] = bin[offset...(offset += 20)].rstrip
      raise "invalid XM module" unless bin[offset...(offset += 1)] == "\x1A"

      args[:tracker] = bin[offset...(offset += 20)].rstrip

      args[:version_number] = bin[offset...(offset += 2)].unpack1("S<")

      args[:header_size] = bin[offset...(offset += 4)].unpack1("L<")

      %i[song_length restart_position number_of_channels number_of_patterns
         number_of_instruments flags default_tempo default_bpm].each do |attr|
        args[attr] = bin[offset...(offset += 2)].unpack1("S<")
      end

      args[:pattern_order] = bin[offset...(offset += args[:song_length])].unpack("C*")

      puts "song #{args[:title].inspect}"
      puts "tracker #{args[:tracker].inspect} (#{format('%#06x', args[:version_number])})"
      puts "-" * 25

      ############
      # patterns #
      ############
      offset, args[:patterns] = parse_patterns(bin, args)

      ###############
      # instruments #
      ###############
      offset, args[:instruments] = parse_instruments(bin, args, offset)

      new(args)
    end

    def self.parse_patterns(bin, xm_args)
      patterns = []
      offset = xm_args[:header_size] + 60

      xm_args[:number_of_patterns].times do
        patterns << {}.tap do |pattern_args|
          pattern_args[:header_size] = bin[offset...(offset += 4)].unpack1("L<")
          pattern_args[:packing_type] = bin[offset...(offset += 1)].unpack1("C")
          pattern_args[:number_of_rows] = bin[offset...(offset += 2)].unpack1("S<")
          pattern_args[:packed_size] = bin[offset...(offset += 2)].unpack1("S<")
          offset += pattern_args[:packed_size] # skip for now
        end
      end

      [offset, patterns]
    end

    def self.parse_instruments(bin, xm_args, offset)
      instruments = []

      xm_args[:number_of_instruments].times do
        instruments << {}.tap do |instrument_args|
          # 1st part
          instrument_args[:header_size] = bin[offset...(offset += 4)].unpack1("L<")
          instrument_args[:name] = bin[offset...(offset += 22)].rstrip
          instrument_args[:type] = bin[offset...(offset += 1)].unpack1("C")
          instrument_args[:number_of_samples] = bin[offset...(offset += 2)].unpack1("S<")

          puts "instrument #{instrument_args[:name].inspect}:"
          puts "- header_size: #{format('%#06x', instrument_args[:header_size])}"
          puts "- number_of_samples: #{instrument_args[:number_of_samples]}"
          if instrument_args[:number_of_samples].zero?
            offset -= 33 # realignment hack from xmp
            next
          end

          # 2nd part
          instrument_args[:sample_header_size] = bin[offset...(offset += 4)].unpack1("L<")
          puts "- sample_header_size: #{format('%#06x', instrument_args[:sample_header_size])}"
          instrument_args[:sample_keymap_assignments] = bin[offset...(offset += 96)].unpack("C*")
          instrument_args[:volume_envelope] = bin[offset...(offset += 48)].unpack("S<*")
          instrument_args[:panning_envelope] = bin[offset...(offset += 48)].unpack("S<*")

          %i[number_of_volume_points number_of_panning_points
             volume_sustain_point volume_loop_start_point volume_loop_end_point
             panning_sustain_point panning_loop_start_point panning_loop_end_point
             volume_type panning_type
             vibrato_type vibrato_sweep vibrato_depth vibrato_rate].each do |attr|
            instrument_args[attr] = bin[offset...(offset += 1)].unpack1("C")
            print "- #{attr}: #{format('%#04x', instrument_args[attr])} -- "
            p instrument_args[attr]
          end

          instrument_args[:volume_fadeout] = bin[offset...(offset += 2)].unpack1("S<")
          instrument_args[:reserved] = bin[offset...(offset += 22)].unpack("S<*")
          puts "- volume_fadeout: #{format('%#06x', instrument_args[:volume_fadeout])}"

          offset, instrument_args[:samples] = parse_samples(bin, instrument_args, offset)
        end
      end

      [offset, instruments]
    end

    def self.parse_samples(bin, instrument_args, offset)
      samples = []

      # first the sample headers ...
      puts "- samples:"
      instrument_args[:number_of_samples].times do
        samples << {}.tap do |sample_args|
          start_offset = offset
          sample_args[:sample_length] = bin[offset...(offset += 4)].unpack1("L<")
          sample_args[:sample_loop_start] = bin[offset...(offset += 4)].unpack1("L<")
          sample_args[:sample_loop_length] = bin[offset...(offset += 4)].unpack1("L<")

          sample_args[:volume] = bin[offset...(offset += 1)].unpack1("C")
          sample_args[:finetune] = bin[offset...(offset += 1)].unpack1("c")
          sample_args[:type] = bin[offset...(offset += 1)].unpack1("C")
          sample_args[:panning] = bin[offset...(offset += 1)].unpack1("C")
          sample_args[:relative_note_number] = bin[offset...(offset += 1)].unpack1("c")
          sample_args[:packing_type] = bin[offset...(offset += 1)].unpack1("C")

          sample_args[:name] = bin[offset...(offset += 22)].rstrip
          puts "  - name: #{sample_args[:name].inspect}"
          puts "    type: #{ExtendedModule::Helpers.sample_type(sample_args[:type])}bit"
          puts "    length: #{format('%#06x', sample_args[:sample_length])}"
          puts "    loop_start: #{format('%#06x', sample_args[:sample_loop_start])}"
          puts "    loop_length: #{format('%#06x', sample_args[:sample_loop_length])}"
          puts "    volume: #{format('%#04x', sample_args[:volume])}"
          puts "    finetune: #{format('%#04x', sample_args[:finetune])}"
          puts "    panning: #{format('%#04x', sample_args[:panning])}"
          diff = instrument_args[:sample_header_size] - (offset - start_offset)
          puts "    offset diff from instrument header: #{diff}"
          raise unless diff.zero?
        end
      end

      # ... then the sample data!
      samples.each do |sample_args|
        sample_args[:raw_data] = bin[offset...(offset += sample_args[:sample_length])]
        sample_args[:data] = unpack_sample_data(sample_args)
      end

      [offset, samples]
    end

    def self.unpack_sample_data(sample_args)
      puts "unpacking sample #{sample_args[:name].inspect} ..."
      unpack_str = case ExtendedModule::Helpers.sample_type(sample_args[:type])
                   when 8 then "c*"
                   when 16 then "s<*"
                   else
                     raise "this should never happen(tm)"
                   end
      packed_samples = sample_args.delete(:raw_data).unpack(unpack_str)

      raise "ADPCM samples are not supported yet" if sample_args[:packing_type] == 0xAD

      # delta compression
      [].tap do |samples|
        previous_sample = 0
        packed_samples.each do |packed_sample|
          samples << (previous_sample += packed_sample)
        end
      end
    end
  end
end
