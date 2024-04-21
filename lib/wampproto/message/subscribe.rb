# frozen_string_literal: true

module Wampproto
  module Message
    # abort message
    class Subscribe < Base
      attr_reader :request_id, :options, :topic

      def initialize(request_id, options, topic)
        super()
        @request_id = Validate.int!("Request Id", request_id)
        @options = Validate.hash!("Options", options)
        @topic = Validate.string!("Topic", topic)
      end

      def marshal
        [Type::SUBSCRIBE, request_id, options, topic]
      end

      def self.parse(wamp_message)
        _type, request_id, options, topic = wamp_message
        new(request_id, options, topic)
      end
    end
  end
end
