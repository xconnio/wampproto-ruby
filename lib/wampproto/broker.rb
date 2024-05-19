# frozen_string_literal: true

module Wampproto
  # Wampproto broker implementation
  class Broker # rubocop:disable Metrics/ClassLength
    attr_reader :subscriptions_by_session, :subscriptions_by_topic, :id_gen, :sessions

    def initialize(id_gen = IdGenerator.new)
      @id_gen = id_gen
      @subscriptions_by_session = {}
      @subscriptions_by_topic = {}
      @sessions = {}
    end

    def add_session(details)
      session_id = details.session_id

      error_message = "cannot add session twice"
      raise KeyError, error_message if subscriptions_by_session.include?(session_id)

      subscriptions_by_session[session_id] = {}
      sessions[session_id] = details
    end

    def remove_session(session_id)
      error_message = "cannot remove non-existing session"
      raise KeyError, error_message unless subscriptions_by_session.include?(session_id)

      subscriptions = subscriptions_by_session.delete(session_id) || {}
      subscriptions.each do |subscription_id, topic|
        remove_topic_subscriber(topic, subscription_id, session_id)
      end
      sessions.delete(session_id)
    end

    def subscription?(topic)
      subscriptions = subscriptions_by_topic[topic]
      return false unless subscriptions

      subscriptions.any?
    end

    def receive_message(session_id, message)
      case message
      when Message::Subscribe then handle_subscribe(session_id, message)
      when Message::Unsubscribe then handle_unsubscribe(session_id, message)
      when Message::Publish then handle_publish(session_id, message)
      else
        raise ValueError, "message type not supported"
      end
    end

    def handle_publish(session_id, message) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      error_message = "cannot publish, session #{session_id} doesn't exist"
      raise ValueError, error_message unless subscriptions_by_session.include?(session_id)

      subscriptions = subscriptions_by_topic.fetch(message.topic, {})
      return if subscriptions.empty?

      publication_id = id_gen.next

      messages = []
      if message.options[:acknowledge]
        published = Message::Published.new(message.request_id, publication_id)
        messages << MessageWithRecipient.new(published, session_id)
      end
      subscription_id, session_ids = subscriptions.first

      event_options = event_details_for(session_id, message)
      event = Message::Event.new(subscription_id, publication_id, event_options, *message.args, **message.kwargs)

      session_ids.each_with_object(messages) do |recipient_id, list|
        list << MessageWithRecipient.new(event, recipient_id) unless exclude?(message, session_id, recipient_id)
      end
    end

    def handle_subscribe(session_id, message)
      error_message = "cannot subscribe, session #{session_id} doesn't exist"
      raise ValueError, error_message unless subscriptions_by_session.include?(session_id)

      subscription_id = find_subscription_id_from(message.topic)
      add_topic_subscriber(message.topic, subscription_id, session_id)
      subscriptions_by_session[session_id][subscription_id] = message.topic

      subscribed = Message::Subscribed.new(message.request_id, subscription_id)
      MessageWithRecipient.new(subscribed, session_id)
    end

    def handle_unsubscribe(session_id, message) # rubocop:disable  Metrics/MethodLength, Metrics/AbcSize
      error_message = "cannot unsubscribe, session #{session_id} doesn't exist"
      raise ValueError, error_message unless subscriptions_by_session.include?(session_id)

      subscriptions = subscriptions_by_session.fetch(session_id)

      unless subscriptions.include?(message.subscription_id)
        error = Message::Error.new(Message::Type::UNSUBSCRIBE, message.request_id, {},
                                   "wamp.error.no_such_subscription")
        return MessageWithRecipient.new(error, session_id)
      end

      topic = subscriptions.fetch(message.subscription_id)

      remove_topic_subscriber(topic, message.subscription_id, session_id)
      subscriptions_by_session[session_id].delete(message.subscription_id)

      unsubscribed = Message::Unsubscribed.new(message.request_id)
      MessageWithRecipient.new(unsubscribed, session_id)
    end

    private

    def find_subscription_id_from(topic)
      subscription_id, = subscriptions_by_topic.fetch(topic, {}).first
      return subscription_id if subscription_id

      id_gen.next
    end

    def remove_topic_subscriber(topic, subscription_id, session_id)
      subscriptions = subscriptions_by_topic.fetch(topic, {})
      return if subscriptions.empty?

      if subscriptions.one? && subscriptions[subscription_id].include?(session_id)
        return subscriptions_by_topic.delete(topic)
      end

      subscriptions_by_topic[topic][subscription_id].delete(session_id)
    end

    def add_topic_subscriber(topic, subscription_id, session_id)
      subscriptions = subscriptions_by_topic.fetch(topic, {})
      if subscriptions.empty?
        subscriptions[subscription_id] = [session_id]
      else
        sessions = subscriptions.fetch(subscription_id, [])
        sessions << session_id unless sessions.include?(session_id)
        subscriptions[subscription_id] = sessions
      end
      subscriptions_by_topic[topic] = subscriptions
    end

    def exclude?(message, session_id, recipient_id)
      return false if session_id != recipient_id

      message.options.fetch(:exclude_me, true)
    end

    def event_details_for(session_id, message)
      return {} unless message.options.include?(:disclose_me)

      session = sessions[session_id]
      { publisher: session_id, publisher_authid: session.authid, publisher_authrole: session.authrole }
    end
  end
end
