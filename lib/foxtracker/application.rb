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
      xm = Foxtracker::Parser.read(@filename)
      require "pp"
      pp xm
    ensure
      binding.irb
    end
  end
end
