# frozen_string_literal: true

module Wampproto
  module Message
    # Base Interface for the Message(s)
    class Base
      class << self
        def parse(msg)
          raise NotImplementedError
        end

        def type
          # to_s is added to satisfy RBS else they are not required
          const = name.to_s.split("::").last.to_s.upcase
          Wampproto::Message::Type.const_get(const)
        end
      end

      def marshal
        raise NotImplementedError
      end

      def type
        # to_s is added to satisfy RBS else they are not required
        const = self.class.name.to_s.split("::").last.to_s.upcase
        Wampproto::Message::Type.const_get(const)
      end
    end
  end
end
