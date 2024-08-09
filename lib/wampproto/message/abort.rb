# frozen_string_literal: true

module Wampproto
  module Message
    # interface for abort fields
    class IAbortFields
      def details
        raise NotImplementedError
      end

      def reason
        raise NotImplementedError
      end

      def args
        raise NotImplementedError
      end

      def kwargs
        raise NotImplementedError
      end
    end

    # abort fields
    class AbortFields < IAbortFields
      attr_reader :details, :reason, :args, :kwargs

      def initialize(details, reason, *args, **kwargs)
        super()
        @details = details
        @reason = reason
        @args = args
        @kwargs = kwargs
      end
    end

    # abort message
    class Abort < Base
      attr_reader :details, :reason, :args, :kwargs

      TEXT = "ABORT"
      VALIDATION_SPEC = Message::ValidationSpec.new(
        3,
        5,
        TEXT,
        {
          1 => Message::Util.method(:validate_details),
          2 => Message::Util.method(:validate_reason),
          3 => Message::Util.method(:validate_args),
          4 => Message::Util.method(:validate_kwargs)
        }
      )

      def initialize(details, reason, *args, **kwargs)
        super()
        @details = details
        @reason = reason
        @args = args
        @kwargs = kwargs
      end

      def self.with_fields(fields)
        new(fields.details, fields.reason, *fields.args, **fields.kwargs)
      end

      def marshal
        @marshal = [Type::ABORT, details, reason]
        @marshal << args if kwargs.any? || args.any?
        @marshal << kwargs if kwargs.any?
        @marshal
      end

      def self.parse(wamp_message)
        fields = Util.validate_message(wamp_message, Type::ABORT, VALIDATION_SPEC)
        fields.args ||= []
        fields.kwargs ||= {}
        Abort.with_fields(fields)
      end
    end
  end
end
