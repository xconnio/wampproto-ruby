# frozen_string_literal: true

module Wampproto
  module Message
    # event message
    class Event < Base
      attr_reader :subscription_id, :publication_id, :details, :args, :kwargs

      def initialize(subscription_id, publication_id, details, *args, **kwargs)
        super()
        @subscription_id  = Validate.int!("Subscription Id", subscription_id)
        @publication_id   = Validate.int!("Publication Id", publication_id)
        @details          = Validate.hash!("details", details)
        @args             = Validate.array!("Arguments", args)
        @kwargs           = Validate.hash!("Keyword Arguments", kwargs)
      end

      def marshal
        @payload = [Type::EVENT, subscription_id, publication_id, details]
        @payload << args if kwargs.any? || args.any?
        @payload << kwargs if kwargs.any?
        @payload
      end

      def self.parse(wamp_message)
        _type, subscription_id, publication_id, details, args, kwargs = wamp_message
        args   ||= []
        kwargs ||= {}
        new(subscription_id, publication_id, details, *args, **kwargs)
      end
    end
  end
end
