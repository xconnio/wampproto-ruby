# frozen_string_literal: true

require_relative "message/base"
require_relative "message/hello"

module WampProto
  # message root
  module Message
    module Type
      HELLO = 1
    end

    HANDLER = {
      Type::HELLO => Hello
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
