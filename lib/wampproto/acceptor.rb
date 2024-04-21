# frozen_string_literal: true

require_relative "acceptor/request"
require_relative "acceptor/response"
require_relative "acceptor/authenticator"

module Wampproto
  # Accepts Request
  class Acceptor # rubocop:disable Metrics/ClassLength:
    STATE_NONE = 0
    STATE_HELLO_RECEIVED = 1
    STATE_CHALLENGE_SENT = 2
    STATE_WELCOME_SENT = 3
    STATE_ERROR = 4

    ROUTER_ROLES = { dealer: {}, broker: {} }.freeze

    attr_reader :serializer, :session_id, :authmethod, :authenticator
    attr_accessor :state, :session_details

    def initialize(serializer = Serializer::JSON, authenticator = Acceptor::Authenticator)
      @serializer = serializer
      @authenticator = authenticator
      @state = STATE_NONE
      @session_id = create_session_id
      # @authmethod = authenticator.authmethod
      # @session_details = SessionDetails
    end

    def receive(data)
      msg = serializer.deserialize(data)
      to_send = receive_message(msg)

      [serializer.serialize(to_send), to_send.instance_of?(Message::Welcome)]
    end

    def receive_message(msg)
      raise ProtocolViolation, "session was established, not expecting any new messages" if state == STATE_WELCOME_SENT

      case msg
      when Message::Hello
        handle_hello_message(msg)
      when Message::Authenticate
        handle_authenticate_message(msg)
      else
        self.state = STATE_ERROR
        Message::Abort.new({ message: "Received Abort" }, "wamp.error.received_abort")
      end
    end

    private

    def handle_hello_message(msg) # rubocop:disable Metrics/MethodLength
      raise StandardError, "unknown state" if state != STATE_NONE

      @hello = msg
      @authid = msg.authid
      @authmethod = msg.authmethods[0] || "anonymous"

      @request = Wampproto::Acceptor::Request.new(msg)
      @response = authenticator.authenticate(@request)

      case @authmethod
      when "cryptosign"
        handle_cryptosign_hello(msg)
      when "ticket"
        handle_ticket_hello(msg)
      when "wampcra"
        handle_wampcra_hello(msg)
      when "anonymous"
        handle_anonymous_hello(msg)
      else
        raise StandardError, "unknown method"
      end
    end

    def handle_wampcra_hello(msg)
      @challenge = Auth::Cra.create_challenge(session_id, msg.authid, @response.authrole, "dynamic")
      self.state = STATE_CHALLENGE_SENT

      Message::Challenge.new(@authmethod, { challenge: @challenge })
    end

    def handle_ticket_hello(_msg)
      self.state = STATE_CHALLENGE_SENT
      Message::Challenge.new(@authmethod, {})
    end

    def handle_cryptosign_hello(msg)
      @public_key = msg.authextra[:pubkey]
      raise StandardError, "authextra must contain pubkey for cryptosign" unless @public_key

      @challenge = Auth::Cryptosign.create_challenge
      self.state = STATE_CHALLENGE_SENT

      Message::Challenge.new(@authmethod, { challenge: @challenge })
    end

    def handle_anonymous_hello(msg)
      self.state = STATE_WELCOME_SENT
      welcome = Wampproto::Message::Welcome.new(
        session_id, {
          roles: ROUTER_ROLES, authid: "anonymous", authmethod: "anonymous", authrole: "anonymous"
        }
      )
      self.session_details = SessionDetails.new(session_id, msg.realm, welcome.authid, welcome.authrole)

      welcome
    end

    def handle_authenticate_message(msg) # rubocop:disable Metrics/MethodLength
      raise StandardError, "unknown state" if state != STATE_CHALLENGE_SENT

      @auth_request = AuthenticateRequest.new(msg, @request)
      @response = authenticator.authenticate(@auth_request)

      case @authmethod
      when "cryptosign"
        handle_cryptosign_authenticate(msg)
      when "ticket"
        handle_ticket_authenticate(msg)
      when "wampcra"
        handle_wampcra_authenticate(msg)
      else
        Message::Abort.new({ message: "Invalid AuthMethod: #{@authmethod}" }, "wamp.error.protocol_violation")
      end
    end

    def handle_wampcra_authenticate(msg)
      return abort_message unless Wampproto::Auth::Cra.verify_challenge(msg.signature, @challenge, @response.secret)

      self.state = STATE_WELCOME_SENT
      welcome = Wampproto::Message::Welcome.new(
        session_id, {
          roles: ROUTER_ROLES, authid: @authid, authmethod: @authmethod, authrole: @response.authrole
        }
      )
      self.session_details = SessionDetails.new(session_id, @hello.realm, welcome.authid, welcome.authrole)

      welcome
    end

    def abort_message
      Message::Abort.new({ message: "Unable to authenticate user" }, "wamp.error.invalid_credentials")
    end

    def handle_ticket_authenticate(msg)
      return abort_message unless @response.secret == msg.signature

      self.state = STATE_WELCOME_SENT
      welcome = Wampproto::Message::Welcome.new(
        session_id, {
          roles: ROUTER_ROLES, authid: @authid, authmethod: @authmethod, authrole: @response.authrole
        }
      )
      self.session_details = SessionDetails.new(session_id, @hello.realm, welcome.authid, welcome.authrole)

      welcome
    end

    def handle_cryptosign_authenticate(msg)
      return abort_message unless Auth::Cryptosign.verify_challenge(msg.signature, @challenge, @public_key)

      self.state = STATE_WELCOME_SENT
      welcome = Wampproto::Message::Welcome.new(
        session_id, {
          roles: ROUTER_ROLES, authid: @authid, authmethod: @authmethod, authrole: "user"
        }
      )
      self.session_details = SessionDetails.new(session_id, @hello.realm, welcome.authid, welcome.authrole)

      welcome
    end

    def create_session_id
      rand(100_000..9_007_199_254_740_992)
    end
  end
end
