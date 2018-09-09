# frozen_string_literal: true

require "foxtracker/errors"
require "foxtracker/parser/base"
require "foxtracker/parser/extended_module"
require "foxtracker/parser/symphonie_module"

module Foxtracker
  module Parser
    module_function

    def read(filename, debug: false)
      parse IO.binread(filename), debug: debug
    end

    def parse(bin, debug: false)
      Foxtracker::Parser::Base.parsers.each do |klass|
        puts "trying to parse with #{klass}... " if debug
        return klass.parse(bin, debug: debug)
      rescue Errors::WrongFormat
        next
      end

      raise Errors::WrongFormat.new("there is no parser for this module format yet")
    end
  end
end
