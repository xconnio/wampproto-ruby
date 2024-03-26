# frozen_string_literal: true

module WampProto
  module Message
    # Base Interface for the Message(s)
    class Base
      class << self
        def parse(msg)
          raise NotImplementedError
        end
      end

      def payload
        raise NotImplementedError
      end
    end
  end
end
