# frozen_string_literal: true

module Wampproto
  # Session
  class Session # rubocop:disable Metrics/ClassLength
    attr_reader :serializer

    def initialize(serializer = Serializer::JSON)
      @serializer = serializer
      init_state
    end

    ACCESSORS = %i[
      call_requests
      register_requests
      registrations
      invocation_requests
      unregister_requests

      publish_requests
      subscribe_requests
      subscriptions
      unsubscribe_requests
    ].freeze

    def send_message(msg) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      case msg
      when Message::Call
        call_requests[msg.request_id] = msg.request_id
      when Message::Register
        register_requests[msg.request_id] = msg.request_id
      when Message::Unregister
        unregister_requests[msg.request_id] = msg.registration_id
      when Message::Yield
        unless invocation_requests.include?(msg.request_id)
          raise ValueError, "cannot yield for unknown invocation request"
        end

        invocation_requests.delete(msg.request_id)
      when Message::Publish
        publish_requests[msg.request_id] = msg.request_id if msg.options.fetch(:acknowledge, false)
      when Message::Subscribe
        subscribe_requests[msg.request_id] = msg.request_id
      when Message::Unsubscribe
        unsubscribe_requests[msg.request_id] = msg.subscription_id
      when Message::Error
        error_message = "send only supported for invocation error"
        raise ValueError, error_message if msg.message_type != Message::Invocation.type

        invocation_requests.delete(msg.request_id)
      end

      serializer.serialize(msg)
    end

    def receive(data)
      msg = serializer.deserialize(data)
      receive_message(msg)
    end

    def receive_message(msg) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      case msg
      when Message::Result
        error_message = "received RESULT for invalid request_id"
        raise ValueError, error_message unless call_requests.delete(msg.request_id)
      when Message::Registered
        error_message = "received REGISTERED for invalid request_id"
        raise ValueError, error_message unless register_requests.delete(msg.request_id)

        registrations[msg.registration_id] = msg.registration_id
      when Message::Unregistered
        error_message = "received UNREGISTERED for invalid request_id"
        registration_id = unregister_requests.delete(msg.request_id)
        raise ValueError, error_message unless registration_id

        error_message = "received UNREGISTERED for invalid registration_id"
        raise ValueError, error_message unless registrations.delete(registration_id)
      when Message::Invocation
        error_message = "received INVOCATION for invalid registration_id"
        raise ValueError, error_message unless registrations.delete(msg.registration_id)

        invocation_requests[msg.request_id] = msg.request_id
      when Message::Published
        error_message = "received PUBLISHED for invalid topic"
        raise ValueError, error_message unless publish_requests.delete(msg.request_id)
      when Message::Subscribed
        error_message = "received SUBSCRIBED for invalid request_id"
        raise ValueError, error_message unless subscribe_requests.delete(msg.request_id)

        subscriptions[msg.subscription_id] = msg.subscription_id
      when Message::Unsubscribed
        error_message = "received UNSUBSCRIBED for invalid request_id"
        subscription_id = unsubscribe_requests.delete(msg.request_id)
        raise ValueError, error_message unless subscription_id

        error_message = "received UNSUBSCRIBED for invalid subscription_id"
        raise ValueError, error_message unless subscriptions.delete(subscription_id)
      when Message::Event
        error_message = "received EVENT for invalid subscription_id"
        raise ValueError, error_message unless subscriptions.include?(msg.subscription_id)
      when Message::Error
        case msg.message_type
        when Message::Call.type
          error_message = "received ERROR for invalid call request"
          raise ValueError, error_message unless call_requests.delete(msg.request_id)
        when Message::Register.type
          error_message = "received ERROR for invalid register request"
          raise ValueError, error_message unless register_requests.delete(msg.request_id)
        when Message::Unregister.type
          error_message = "received ERROR for invalid unregister request"
          raise ValueError, error_message unless unregister_requests.delete(msg.request_id)
        when Message::Subscribe.type
          error_message = "received ERROR for invalid subscribe request"
          raise ValueError, error_message unless subscribe_requests.delete(msg.request_id)
        when Message::Unsubscribe.type
          error_message = "received ERROR for invalid unsubscribe request"
          raise ValueError, error_message unless unsubscribe_requests.delete(msg.request_id)
        when Message::Publish.type
          error_message = "received ERROR for invalid publish request"
          raise ValueError, error_message unless publish_requests.delete(msg.request_id)
        else
          error_message = "unknown error message type #{msg.class}"
          raise ValueError, error_message
        end
      when Message::Abort
        p [:session, :abort, msg]
      else
        raise ValueError, "unknown message #{msg.class}"
      end

      msg
    end

    private

    attr_reader(*ACCESSORS)

    def init_state
      ACCESSORS.each do |attr|
        instance_variable_set("@#{attr}", {})
      end
    end
  end
end
