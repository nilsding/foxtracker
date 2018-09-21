# frozen_string_literal: true

require "dry-types"
require "dry-struct"

require "foxtracker/parser"

module Foxtracker
  class Application
    def initialize(argv)
      @filename = argv.first
    end

    def run
      mod = Foxtracker::Parser.read(@filename, debug: true)
      puts "Parsing successful.  Now play with it!"
    rescue StandardError => e
      raise
    ensure
      binding.irb
    end
  end
end
