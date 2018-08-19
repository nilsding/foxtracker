# frozen_string_literal: true

require "foxtracker/parser/extended_module"

module Foxtracker
  module Parser
    module_function

    def read(filename)
      parse IO.binread(filename)
    end

    def parse(bin)
      ExtendedModule.parse(bin)
    end
  end
end
