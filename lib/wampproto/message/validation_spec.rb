# frozen_string_literal: true

module Wampproto
  module Message
    # validation spec
    class ValidationSpec
      attr_reader :min_length, :max_length, :message, :spec

      def initialize(min_length, max_length, message, spec)
        @min_length = min_length
        @max_length = max_length
        @message = message
        @spec = spec
      end
    end
  end
end
