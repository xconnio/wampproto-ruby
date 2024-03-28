# frozen_string_literal: true

module Wampproto
  module Message
    # Wamp Authenticate message
    class Authenticate < Base
      attr_reader :signature, :extra

      def initialize(signature, extra = {})
        super()
        @signature = Validate.string!("Signature", signature)
        @extra = Validate.hash!("Extra", extra)
      end

      def marshal
        [Type::AUTHENTICATE, signature, extra]
      end

      def self.parse(wamp_message)
        _type, signature, extra = wamp_message
        new(signature, extra)
      end
    end
  end
end
