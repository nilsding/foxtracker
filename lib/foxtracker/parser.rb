# frozen_string_literal: true

require "foxtracker/parser/extended_module"

module Foxtracker
  module Parser
    module_function

    def read(filename, debug: false)
      parse IO.binread(filename), debug: debug
    end

    def parse(bin, debug: false)
      ExtendedModule.parse(bin, debug: debug)
    end
  end
end
