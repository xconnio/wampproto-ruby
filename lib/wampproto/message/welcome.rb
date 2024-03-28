# frozen_string_literal: true

module Wampproto
  module Message
    # welcome message
    class Welcome < Base
      attr_reader :session_id, :details

      def initialize(session_id, details = {})
        super()
        @session_id = Validate.int!("Session Id", session_id)
        @details = Validate.hash!("Details", details)
      end

      def marshal
        [Type::WELCOME, @session_id, @details]
      end

      def self.parse(wamp_message)
        _type, session_id, details = wamp_message
        new(session_id, details)
      end
    end
  end
end
