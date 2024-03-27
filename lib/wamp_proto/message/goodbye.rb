# frozen_string_literal: true

module WampProto
  module Message
    # abort message
    class Goodbye < Base
      attr_reader :details, :reason

      def initialize(details, reason)
        super()
        @details = Validate.hash!("Details", details)
        @reason = Validate.string!("Reason", reason)
      end

      def payload
        [Type::GOODBYE, details, reason]
      end

      def self.parse(wamp_message)
        _type, details, reason = Validate.greater_than_equal!(wamp_message, 3)
        new(details, reason)
      end
    end
  end
end
