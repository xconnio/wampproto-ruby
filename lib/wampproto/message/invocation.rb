# frozen_string_literal: true

module Wampproto
  module Message
    # abort message
    class Invocation < Base
      attr_reader :request_id, :registration_id, :details, :args, :kwargs

      def initialize(request_id, registration_id, details, *args, **kwargs)
        super()
        @request_id = Validate.int!("Request Id", request_id)
        @registration_id = Validate.int!("Registration Id", registration_id)
        @details = Validate.hash!("Details", details)
        @args = Validate.array!("Arguments", args)
        @kwargs = Validate.hash!("Keyword Arguments", kwargs)
      end

      def marshal
        @payload = [Type::INVOCATION, request_id, registration_id, details]
        @payload << args if kwargs.any? || args.any?
        @payload << kwargs if kwargs.any?
        @payload
      end

      def self.parse(wamp_message)
        _type, request_id, registration_id, details, args, kwargs = wamp_message
        args   ||= []
        kwargs ||= {}
        new(request_id, registration_id, details, *args, **kwargs)
      end
    end
  end
end
