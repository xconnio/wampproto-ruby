# frozen_string_literal: true

module Wampproto
  module Message
    # abort message
    class Unsubscribe < Base
      attr_reader :request_id, :subscription_id

      def initialize(request_id, subscription_id)
        super()
        @request_id = Validate.int!("Request Id", request_id)
        @subscription_id = Validate.int!("Subscription Id", subscription_id)
      end

      def marshal
        [Type::UNSUBSCRIBE, request_id, subscription_id]
      end

      def self.parse(wamp_message)
        _type, request_id, subscription_id = Validate.length!(wamp_message, 3)
        new(request_id, subscription_id)
      end
    end
  end
end
