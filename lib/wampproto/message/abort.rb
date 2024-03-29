# frozen_string_literal: true

module Wampproto
  module Message
    # abort message
    class Abort < Base
      attr_reader :details, :reason, :args, :kwargs

      def initialize(details, reason, *args, **kwargs)
        super()
        @details = Validate.hash!("Details", details)
        @reason = Validate.string!("Reason", reason)
        @args   = Validate.array!("Arguments", args)
        @kwargs = Validate.hash!("Keyword Arguments", kwargs)
      end

      def marshal
        @marshal = [Type::ABORT, details, reason]
        @marshal << args if kwargs.any? || args.any?
        @marshal << kwargs if kwargs.any?
        @marshal
      end

      def self.parse(wamp_message)
        _type, details, reason, args, kwargs = wamp_message
        args   ||= []
        kwargs ||= {}
        new(details, reason, *args, **kwargs)
      end
    end
  end
end
