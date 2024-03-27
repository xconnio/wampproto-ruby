# frozen_string_literal: true

require_relative "message/base"
require_relative "message/hello"
require_relative "message/welcome"
require_relative "message/abort"
require_relative "message/challenge"
require_relative "message/authenticate"
require_relative "message/goodbye"

module WampProto
  # message root
  module Message
    module Type
      HELLO = 1
      WELCOME = 2
      ABORT = 3
      CHALLENGE = 4
      AUTHENTICATE = 5
      GOODBYE = 6
    end

    HANDLER = {
      Type::HELLO => Hello,
      Type::WELCOME => Welcome,
      Type::ABORT => Abort,
      Type::CHALLENGE => Challenge,
      Type::AUTHENTICATE => Authenticate,
      Type::GOODBYE => Goodbye
    }.freeze

    def self.resolve(wamp_message)
      type, = Validate.array!("Wamp Message", wamp_message)
      begin
        HANDLER[type].parse(wamp_message)
      rescue StandardError => e
        p wamp_message
        raise e
      end
    end
  end
end
