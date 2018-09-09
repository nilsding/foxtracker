# frozen_string_literal: true

require "foxtracker/errors"
require "foxtracker/parser/base"
require "foxtracker/format/symphonie_module"

module Foxtracker
  module Parser
    # The SymphonieModule class parses modules (not songs!) created with the
    # Amiga program Symphonie Pro.
    class SymphonieModule < Base
      def parse(bin, debug: false)
        bin = -bin
        @debug = debug
        args = {}
        offset = 0

        ##########
        # header #
        ##########
        raise Errors::WrongFormat.new("not a SymMOD module") unless bin[offset...(offset += 4)] == "SymM"

        args[:version_number] = bin[offset...(offset += 4)].unpack1("l>")
        raise Errors::InvalidModule.new("SymMOD version is not 1") unless args[:version_number] == 1

        parse_modheads(bin, args, offset)

        binding.irb

        Format::SymphonieModule.new(args)
      end

      private

      # identifier => [parser_method type_name]
      #
      # the parser methods to be used are defined in the assembly source in
      # `ExtractModuleParts_JL` and `LoadModuleParts_JL`
      MODHEAD_TYPES = {
        # these types are followed by a long with the value
        -1 => %i[long number_of_channels], 
        -2 => %i[long number_of_rows], # Symphonie calls it "track length"
        -3 => %i[long number_of_patterns],
        -4 => %i[long number_of_instruments],
        -5 => %i[long notesize],
        -6 => %i[long system_speed],
        -7 => %i[long is_song],
        -10 => %i[block song_data],
        -11 => %i[sample sample],
        -12 => %i[empty_sample empty_sample],
        -13 => %i[block note_data],
        -14 => %i[sample_names sample_names],
        -15 => %i[block sequence],
        -16 => %i[block info_text],
        -17 => %i[delta_sample delta_sample],
        -18 => %i[delta_16_sample delta_16],
        -20 => %i[block info_obj],
        -19 => %i[block info_type],
        -21 => %i[block string], # 3.3d
        0 => %i[eof eof],
        10 => %i[long ng_sample_boost],
        11 => %i[long pitch_diff],
        12 => %i[long sample_diff]
      }.freeze

      private_constant :MODHEAD_TYPES

      def parse_modheads(bin, args, offset)
        args[:instruments] = []
        @current_instrument = 0

        while offset < bin.size
          print format("[%08x] ", offset) if @debug
          modhead_parser, modhead_name = MODHEAD_TYPES.fetch(bin[offset...(offset += 4)].unpack1("l>"))
          if modhead_parser == :eof
            puts "got EOF, goodbye!" if @debug
            break
          end
          print "got a #{modhead_name}, using #{modhead_parser} ... " if @debug
          offset = send(:"parse_modhead_#{modhead_parser}", bin, modhead_name, args, offset)
        end

        offset
      end

      def parse_modhead_long(bin, modhead_name, args, offset)
        value = bin[offset...(offset += 4)].unpack1("l>")

        puts " # => #{value.inspect}" if @debug
        args[modhead_name] = value

        offset
      end

      def parse_modhead_block(bin, modhead_name, args, offset)
        length = bin[offset...(offset += 4)].unpack1("l>")

        # skip lol
        data = bin[offset...(offset += length)]
        case modhead_name
        when :info_text
          args[modhead_name] = data
          puts " # => #{data.size} bytes"
        else
          args[modhead_name] = data
          puts " # => skip #{length} bytes" if @debug
        end

        offset
      end

      def parse_modhead_sample(bin, _modhead_name, args, offset, delta_extract: false, delta_type: 8)
        if delta_extract || delta_type == 16
          # Not implemented yet.
          #
          # if you want to implement this, take a look at Symphonie's assembly
          # source code and look for the labels `ExtractHunkSample`,
          # `ExtractHSMP_D8` and `ExtractHSMP_D16`.
          raise NotImplementedError.new("delta extraction is not supported yet")
        end

        length = bin[offset...(offset += 4)].unpack1("l>")
        data = bin[offset...(offset += length)].unpack("c*") # seems to be raw sample files

        args[:instruments][@current_instrument][:data] = data
        @current_instrument += 1

        puts " # => #{data.size} bytes" if @debug

        offset
      end

      def parse_modhead_empty_sample(_bin, _modhead_name, args, offset)
        # Nothing to see here.
        puts " # => nothing to parse..." if @debug
        args[:instruments][@current_instrument][:data] = nil
        @current_instrument += 1

        offset
      end

      SAMPLES_MAX = 256 # asm: MaxNumb_Samples
      SAMPLES_NAME_MAX = 256 # asm: SampleNameMaxLen
      SAMPLES_UNPACK_STR = "a#{SAMPLES_NAME_MAX}" * SAMPLES_MAX

      private_constant :SAMPLES_MAX, :SAMPLES_NAME_MAX, :SAMPLES_UNPACK_STR

      def parse_modhead_sample_names(bin, _modhead_name, args, offset)
        length = bin[offset...(offset += 4)].unpack1("l>")

        sample_names = bin[offset...(offset += length)].unpack(SAMPLES_UNPACK_STR)[0...args[:number_of_instruments]]

        val = ->(name, off, packstr = "c") { name[off].unpack1(packstr) }
        args[:instruments] = sample_names.map do |name|
          # The assembly version just maps it into memory, which may result in
          # the name being garbled by previous sample names. That's why we have
          # to split it by 0x00 (string terminator) and take the first element
          # of it.
          # Also, sample information seems to be encoded inside the sample name
          # after 128 bytes. So we will extract those here as well.
          # The constants for the offsets are defined in the assembly source,
          # and they start with `SAMPLENAME_`.  I added the comments seen in the
          # source as well, along with some annotations if needed.
          {
            name:              name[0...128].split("\x00").first,
            instrument_type:   val[name, 128], # 0=No Instr, whatever that means.
            loop_start:        val[name, 129], # %
            loop_length:       val[name, 130], # %
            loop_number:       val[name, 131], # 0=ENDLESS, 1-255=#
            multi:             val[name, 132], # 0=MONO
            auto_maximize:     val[name, 133], # 0=NO, 1=YES
            volume:            val[name, 134], # 0=NO, VOLUME in %1...200%
            relation:          val[name, 135], # 0=INDEPENDENT, 1=PARENT, 2=CHILD UNUSED (?????)
            child_number:      val[name, 136], # 0=INDEPENDENT UNUSED
            sample_type:       val[name, 137], # 0=RAW, 1=IFF -- commented in assembly source
            finetune:          val[name, 138], # SIGNED 0=None [-127...+127]
            tune:              val[name, 139], # SIGNED 0=None [-24...+24]
            linesample_flags:  val[name, 140], # LINESAMPLE FLAGS
            filter:            val[name, 141], # 0=NONE
            playflag:          val[name, 142], # 0=NRM
            downsample:        val[name, 143], # 0=NONE
            reso:              val[name, 144], # 0=NONE
            loadflags:         val[name, 145], # 0=NORMAL
            info:              val[name, 146], # BIT0
            range_start:       val[name, 147], # %
            range_length:      val[name, 148], # %
            loop_start_low:    val[name, 150..151, "S>"], # lower bits of loop -- no idea how this works (yet)
            loop_length_low:   val[name, 152..153, "S>"], # lower bits of loop -- no idea how this works (yet)

            reso_filter_flags: val[name, 160], # 4x LP od HP
            reso_filter_numb:  val[name, 161], # Anzahl Punkte
            reso_filter:       val[name, 162], # bis 170

            vfade_status:      val[name, 170],
            vfade_start:       val[name, 171],
            vfade_end:         val[name, 172]
          }
        end

        puts " # => #{args[:instruments].size} instruments defined" if @debug

        offset
      end

      def parse_modhead_delta_sample(bin, modhead_name, args, offset)
        parse_modhead_sample(bin, modhead_name, args, offset, delta_extract: true)
      end

      def parse_modhead_delta_16_sample(bin, modhead_name, args, offset)
        parse_modhead_sample(bin, modhead_name, args, offset, delta_extract: true, delta_type: 16)
      end
    end
  end
end
