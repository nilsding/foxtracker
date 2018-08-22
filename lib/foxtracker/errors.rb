# frozen_string_literal: true

module Foxtracker
  module Errors
    class Base < StandardError; end

    class WrongFormat < Base; end
    class InvalidModule < Base; end
  end
end
