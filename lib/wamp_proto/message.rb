# frozen_string_literal: true

require_relative "message/base"
require_relative "message/hello"
require_relative "message/welcome"
require_relative "message/abort"

module WampProto
  # message root
  module Message
    module Type
      HELLO = 1
      WELCOME = 2
      ABORT = 3
    end

    HANDLER = {
      Type::HELLO => Hello,
      Type::WELCOME => Welcome,
      Type::ABORT => Abort
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