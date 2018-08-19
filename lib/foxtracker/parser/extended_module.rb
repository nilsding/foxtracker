# frozen_string_literal: true

require "foxtracker/parser/base"
require "foxtracker/parser/support/extended_module"
require "foxtracker/format/extended_module"

module Foxtracker
  module Parser
    class ExtendedModule < Base
      def parse(bin)
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

        Format::ExtendedModule.new(args)
      end

      private

      def parse_patterns(bin, xm_args)
        patterns = []
        offset = xm_args[:header_size] + 60

        xm_args[:number_of_patterns].times do |pattern_no|
          patterns << {}.tap do |pattern_args|
            pattern_args[:header_size] = bin[offset...(offset += 4)].unpack1("L<")
            pattern_args[:packing_type] = bin[offset...(offset += 1)].unpack1("C")
            pattern_args[:number_of_rows] = bin[offset...(offset += 2)].unpack1("S<")
            pattern_args[:packed_size] = bin[offset...(offset += 2)].unpack1("S<")
            puts "pattern #{pattern_no.to_s(16)}"
            pattern_args[:channels] = parse_pattern(
              bin[offset...(offset += pattern_args[:packed_size])], xm_args, pattern_args
            )
            # offset += pattern_args[:packed_size] # skip for now
          end
        end

        [offset, patterns]
      end

      def parse_pattern(bin, xm_args, pattern_args)
        pattern = Array.new(xm_args[:number_of_channels])
        offset = 0
        pattern_args[:number_of_rows].times do
          xm_args[:number_of_channels].times do |chan|
            pattern[chan] ||= []
            first_byte = bin[offset...(offset += 1)].unpack1("C")
            note = { note: 0, instrument: 0, volume: 0, effect_type: 0, effect_param: 0 }
            if first_byte & 128 == 128 # packed note
              note[:note]         = bin[offset...(offset += 1)].unpack1("C") if first_byte & 1 == 1
              note[:instrument]   = bin[offset...(offset += 1)].unpack1("C") if first_byte & 2 == 2
              note[:volume]       = bin[offset...(offset += 1)].unpack1("C") if first_byte & 4 == 4
              note[:effect_type]  = bin[offset...(offset += 1)].unpack1("C") if first_byte & 8 == 8
              note[:effect_param] = bin[offset...(offset += 1)].unpack1("C") if first_byte & 16 == 16
              pattern[chan] << note
              next
            end
            note[:note]         = first_byte
            note[:instrument]   = bin[offset...(offset += 1)].unpack1("C")
            note[:volume]       = bin[offset...(offset += 1)].unpack1("C")
            note[:effect_type]  = bin[offset...(offset += 1)].unpack1("C")
            note[:effect_param] = bin[offset...(offset += 1)].unpack1("C")
            pattern[chan] << note
          end
        end
        puts pattern.transpose.map { |chan| chan.map { |note| format("%02d %2x %2x %2x %2x", note[:note], note[:instrument], note[:volume], note[:effect_type], note[:effect_param]) }.join(" | ") }.join("\n")
        pattern
      end

      def parse_instruments(bin, xm_args, offset)
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

      def parse_samples(bin, instrument_args, offset)
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
            puts "    type: #{Support::ExtendedModule.sample_type(sample_args[:type])}bit"
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

      def unpack_sample_data(sample_args)
        puts "unpacking sample #{sample_args[:name].inspect} ..."
        unpack_str = case Support::ExtendedModule.sample_type(sample_args[:type])
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
end
