# frozen_string_literal: true

require_relative "wampproto/version"
require_relative "wampproto/validate"
require_relative "wampproto/message"
require_relative "wampproto/serializer"
require_relative "wampproto/auth"
require_relative "wampproto/id_generator"
require_relative "wampproto/session_details"
require_relative "wampproto/joiner"
require_relative "wampproto/acceptor"
require_relative "wampproto/session"
require_relative "wampproto/message_with_recipient"
require_relative "wampproto/dealer"

module Wampproto
  class Error < StandardError; end

  # ProtocolViolation Exception
  class ProtocolViolation < StandardError
    attr_reader :uri

    def initialize(msg = "Protocol Violation", uri = "wamp.error.protocol_violation")
      @uri = uri
      super(msg)
    end
  end

  class ValueError < StandardError
  end
end
