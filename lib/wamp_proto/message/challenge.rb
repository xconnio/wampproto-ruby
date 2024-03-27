# frozen_string_literal: true

module WampProto
  module Message
    # Wamp Challenge message
    class Challenge < Base
      attr_reader :auth_method, :extra

      def initialize(auth_method, extra = {})
        super()
        @auth_method = Validate.string!("AuthMethod", auth_method)
        @extra = Validate.hash!("Extra", extra)
      end

      def payload
        [Type::CHALLENGE, auth_method, extra]
      end

      def self.parse(wamp_message)
        _type, auth_method, extra = wamp_message
        new(auth_method, extra)
      end
    end
  end
end
