# frozen_string_literal: true

module Wampproto
  CLIENT_ROLES = {
    caller: { features: {} },
    callee: { features: {} },
    publisher: { features: {} },
    subscriber: { features: {} }
  }.freeze

  # Custom Exception
  class ProtocolViolation < StandardError
    attr_reader :uri

    def initialize(msg = "Protocol Violation", uri = "wamp.error.protocol_violation")
      @uri = uri
      super(msg)
    end
  end

  # Handle Joining part of wamp protocol
  class Joiner
    STATE_NONE = 0
    STATE_HELLO_SENT = 1
    STATE_AUTHENTICATE_SENT = 2
    STATE_JOINED = 3

    attr_reader :realm, :serializer, :authenticator
    attr_accessor :state

    def initialize(realm, serializer = Serializer::JSON, authenticator = Auth::Anonymous.new)
      @realm = realm
      @serializer = serializer
      @authenticator = authenticator
      @state = STATE_NONE
    end

    def send_hello # rubocop:disable Metrics/MethodLength
      hello = Message::Hello.new(
        realm,
        {
          roles: CLIENT_ROLES,
          authid: authenticator.authid,
          authmethods: [authenticator.authmethod],
          authextra: authenticator.authextra
        }
      )

      @state = STATE_HELLO_SENT
      serializer.serialize(hello)
    end

    def receive(data)
      message = serializer.deserialize(data)
      to_send = receive_message(message)

      return unless to_send.instance_of?(Message::Authenticate)

      serializer.serialize(to_send)
    end

    def receive_message(msg) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      case msg
      when Message::Welcome
        if state != STATE_HELLO_SENT && state != STATE_AUTHENTICATE_SENT
          raise ProtocolViolation, "Received WELCOME message after session was established"
        end

        @session_details = SessionDetails.new(msg.session_id, realm, msg.authid, msg.authrole)
        self.state = STATE_JOINED
      when Message::Challenge
        raise ProtocolViolation, "Received CHALLENGE message before HELLO message was sent" if state != STATE_HELLO_SENT

        authenticate = authenticator.authenticate(msg)
        self.state = STATE_AUTHENTICATE_SENT
        authenticate
      when Message::Abort
        raise StandardError, "received abort"
      else
        raise StandardError, "received unknown message"
      end
    end
  end
end
