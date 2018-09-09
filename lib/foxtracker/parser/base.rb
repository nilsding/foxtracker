# frozen_string_literal: true

module Foxtracker
  module Parser
    class Base
      def self.parse(*args)
        new.parse(*args)
      end

      def self.parsers
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def parse(*_args)
        raise NotImplementedError
      end
    end
  end
end
