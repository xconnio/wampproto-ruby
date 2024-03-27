# frozen_string_literal: true

module WampProto
  module Message
    # Wamp Interrupt message
    class Interrupt
      attr_reader :request_id, :options

      def initialize(request_id, options = {})
        @request_id = Validate.int!("Request Id", request_id)
        @options = Validate.hash!("Options", options)
      end

      def payload
        [Type::INTERRUPT, request_id, options]
      end

      def self.parse(wamp_message)
        _type, request_id, options = wamp_message
        new(request_id, options)
      end
    end
  end
end
