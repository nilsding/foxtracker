# frozen_string_literal: true

module Foxtracker
  module Format
    module Support
      # HACK: this module builder removes certain attributes from the inspect
      # output as e.g. sample data is really too spammy
      class DryTypesUnspect < Module
        def initialize(*field_names)
          # https://github.com/dry-rb/dry-struct/blob/cb41a5a03/lib/dry/struct.rb#L178
          define_method :inspect do
            klass = self.class
            attrs = klass
                      .attribute_names
                      .reject { |key| field_names.include?(key) }
                      .map { |key| " #{key}=#{@attributes[key].inspect}" }
                      .join
            "#<#{klass.name || klass.inspect}#{attrs}>"
          end
        end
      end
    end
  end
end
