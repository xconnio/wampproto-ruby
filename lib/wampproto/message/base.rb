# frozen_string_literal: true

module Wampproto
  module Message
    # Base Interface for the Message(s)
    class Base
      class << self
        def parse(msg)
          raise NotImplementedError
        end
      end

      def marshal
        raise NotImplementedError
      end
    end
  end
end
