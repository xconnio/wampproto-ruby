# frozen_string_literal: true

module Wampproto
  module Message
    # unregistered message
    class Unregistered < Base
      attr_reader :request_id

      def initialize(request_id)
        super()
        @request_id = Validate.int!("Request Id", request_id)
      end

      def marshal
        [Type::UNREGISTERED, request_id]
      end

      def self.parse(wamp_message)
        _type, request_id = wamp_message
        new(request_id)
      end
    end
  end
end
