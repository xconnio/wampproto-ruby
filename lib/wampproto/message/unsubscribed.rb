# frozen_string_literal: true

module Wampproto
  module Message
    # Unsubscribed message
    class Unsubscribed < Base
      attr_reader :request_id

      def initialize(request_id)
        super()
        @request_id = Validate.int!("Request Id", request_id)
      end

      def marshal
        [Type::UNSUBSCRIBED, request_id]
      end

      def self.parse(wamp_message)
        _type, request_id = Validate.length!(wamp_message, 2)
        new(request_id)
      end
    end
  end
end
