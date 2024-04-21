# frozen_string_literal: true

module Wampproto
  module Message
    # publish message
    class Register < Base
      attr_reader :request_id, :options, :procedure

      def initialize(request_id, options, procedure)
        super()
        @request_id = Validate.int!("Request Id", request_id)
        @options    = Validate.hash!("Options", options)
        @procedure  = Validate.string!("Procedure", procedure)
      end

      def marshal
        [Type::REGISTER, request_id, options, procedure]
      end

      def self.parse(wamp_message)
        _type, request_id, options, procedure = wamp_message
        new(request_id, options, procedure)
      end
    end
  end
end
