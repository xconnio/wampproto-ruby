# frozen_string_literal: true

module Wampproto
  # Wamprpoto Dealer handler
  class Dealer
    attr_reader :registrations_by_procedure, :registrations_by_session, :pending_calls, :pending_invocations, :id_gen

    def initialize(id_gen = IdGenerator.new)
      @registrations_by_session = {}
      @registrations_by_procedure = Hash.new { |h, k| h[k] = {} }
      @pending_calls = {}
      @pending_invocations = {}
      @id_gen = id_gen
    end

    def add_session(session_id)
      error_message = "cannot add session twice"
      raise KeyError, error_message if registrations_by_session.include?(session_id)

      registrations_by_session[session_id] = {}
    end

    def remove_session(session_id)
      error_message = "cannot remove non-existing session"
      raise KeyError, error_message unless registrations_by_session.include?(session_id)

      registrations = registrations_by_session.delete(session_id) || {}
      registrations.each do |registration_id, procedure|
        registrations_by_procedure[procedure].delete(registration_id)
      end
    end

    def registration?(procedure)
      registrations = registrations_by_procedure[procedure]
      return false unless registrations

      registrations.any?
    end

    def receive_message(session_id, message)
      case message
      when Wampproto::Message::Call then handle_call(session_id, message)
      when Message::Yield then handle_yield(session_id, message)
      when Message::Register then handle_register(session_id, message)
      when Message::Unregister then handle_unregister(session_id, message)
      else
        raise ValueError, "message type not supported"
      end
    end

    def handle_call(session_id, message) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      registrations = registrations_by_procedure.fetch(message.procedure, {})
      if registrations.empty?
        error = Message::Error.new(Message::Type::CALL, message.request_id, {}, "wamp.error.no_such_procedure")
        return MessageWithRecipient.new(error, session_id)
      end

      registration_id, callee_id = registrations.first

      pending_calls[callee_id] = {} unless pending_calls.include?(callee_id)
      pending_invocations[callee_id] = {} unless pending_invocations.include?(callee_id)

      # we received call from the "caller" lets call that request_id "1"
      # we need to send invocation message to "callee" let call that request_id "10"
      # we need "caller" id after we have received yield so that request_id will be "10"
      # we need to send request to "caller" to the original request_id 1
      request_id = id_gen.next

      pending_invocations[callee_id][request_id] = session_id

      pending_calls[callee_id][session_id] = message.request_id

      invocation = Message::Invocation.new(
        request_id,
        registration_id,
        {},
        *message.args,
        **message.kwargs
      )

      MessageWithRecipient.new(invocation, callee_id)
    end

    def handle_yield(session_id, message)
      calls = pending_calls.fetch(session_id, {})
      error_message = "no pending calls for session #{session_id}"
      raise ValueError, error_message if calls.empty?

      invocations = pending_invocations[session_id]
      caller_id = invocations.delete(message.request_id).to_i # make steep happy

      request_id = calls.delete(caller_id)

      result = Message::Result.new(request_id, {}, *message.args, **message.kwargs)
      MessageWithRecipient.new(result, caller_id)
    end

    def handle_register(session_id, message)
      error_message = "cannot register, session #{session_id} doesn't exist"
      raise ValueError, error_message unless registrations_by_session.include?(session_id)

      registration_id = id_gen.next
      registrations_by_procedure[message.procedure][registration_id] = session_id
      registrations_by_session[session_id][registration_id] = message.procedure

      registered = Message::Registered.new(message.request_id, registration_id)
      MessageWithRecipient.new(registered, session_id)
    end

    def handle_unregister(session_id, message) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength)
      error_message = "cannot unregister, session #{session_id} doesn't exist"
      raise ValueError, error_message unless registrations_by_session.include?(session_id)

      registrations = registrations_by_session.fetch(session_id)

      unless registrations.include?(message.registration_id)
        error = Message::Error.new(Message::Type::UNREGISTER, message.request_id, {}, "wamp.error.no_such_registration")
        return MessageWithRecipient.new(error, session_id)
      end

      procedure = registrations.fetch(message.registration_id)

      registrations_by_procedure[procedure].delete(message.registration_id)
      registrations_by_session[session_id].delete(message.registration_id)

      unregistered = Message::Unregistered.new(message.request_id)
      MessageWithRecipient.new(unregistered, session_id)
    end
  end
end
