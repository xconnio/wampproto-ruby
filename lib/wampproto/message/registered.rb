# frozen_string_literal: true

module Wampproto
  module Message
    # publish message
    class Registered < Base
      attr_reader :request_id, :registration_id

      def initialize(request_id, registration_id)
        super()
        @request_id = Validate.int!("Request Id", request_id)
        @registration_id = Validate.int!("Registration Id", registration_id)
      end

      def marshal
        [Type::REGISTERED, request_id, registration_id]
      end

      def self.parse(wamp_message)
        _type, request_id, registration_id = wamp_message
        new(request_id, registration_id)
      end
    end
  end
end
