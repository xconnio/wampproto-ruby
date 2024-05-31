# frozen_string_literal: true

module Wampproto
  # Wamprpoto Dealer handler
  class Dealer # rubocop:disable Metrics/ClassLength
    PendingInvocation = Struct.new(:caller_id, :callee_id, :call_id, :invocation_id, :receive_progress, :progress)

    attr_reader :registrations_by_procedure, :registrations_by_session, :pending_calls, :id_gen,
                :sessions

    def initialize(id_gen = IdGenerator.new)
      @registrations_by_session = {}
      @registrations_by_procedure = Hash.new { |h, k| h[k] = {} }
      @pending_calls = {}
      @id_gen = id_gen
      @sessions = {}
    end

    def add_session(details)
      session_id = details.session_id

      error_message = "cannot add session twice"
      raise KeyError, error_message if registrations_by_session.include?(session_id)

      registrations_by_session[session_id] = {}
      sessions[session_id] = details
    end

    def remove_session(session_id)
      error_message = "cannot remove non-existing session"
      raise KeyError, error_message unless registrations_by_session.include?(session_id)

      registrations = registrations_by_session.delete(session_id) || {}
      registrations.each do |registration_id, procedure|
        registrations_by_procedure[procedure].delete(registration_id)
      end
      sessions.delete(session_id)
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

      request_id = id_gen.next

      details = invocation_details_for(session_id, message)

      pending_calls[[callee_id, request_id]] = PendingInvocation.new(
        session_id, callee_id, message.request_id, request_id, details[:receive_progress]
      )

      invocation = Message::Invocation.new(
        request_id,
        registration_id,
        details,
        *message.args,
        **message.kwargs
      )

      MessageWithRecipient.new(invocation, callee_id)
    end

    def invocation_details_for(session_id, message)
      options = {}
      return options if message.options.empty?

      receive_progress = message.options[:receive_progress]
      options.merge!(receive_progress: true) if receive_progress

      return options unless message.options.include?(:disclose_me)

      session = sessions[session_id]
      options.merge({ caller: session_id, caller_authid: session.authid, caller_authrole: session.authrole })
    end

    def handle_yield(session_id, message) # rubocop:disable Metrics/AbcSize
      pending_invocation = pending_calls[[session_id, message.request_id]]
      error_message = "no pending calls for session #{session_id}"
      raise ValueError, error_message if pending_invocation.nil?

      caller_id   = pending_invocation.caller_id
      request_id  = pending_invocation.call_id
      pending_calls.delete([session_id, message.request_id]) unless message.options[:progress]

      result = Message::Result.new(request_id, result_details_for(session_id, message), *message.args, **message.kwargs)
      MessageWithRecipient.new(result, caller_id)
    end

    def result_details_for(session_id, message)
      options = {}
      return options if message.options.empty?

      pending_invocation = pending_calls[[session_id, message.request_id]]

      progress = message.options[:progress] && pending_invocation.receive_progress
      options.merge!(progress:) if progress
      options
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
