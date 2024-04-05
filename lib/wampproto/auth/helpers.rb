# frozen_string_literal: true

module Wampproto
  # Auth classes
  module Auth
    # Auth Helpers
    module Helpers
      def self.included(base)
        base.extend(ClassMethods)
        base.include(ClassMethods)
      end

      # class methods
      module ClassMethods
        def hex_to_binary(hex_string)
          [hex_string].pack("H*")
        end

        def binary_to_hex(binary_string)
          binary_string.unpack1("H*")
        end
      end
    end
  end
end
