# frozen_string_literal: true

require "json"

module Wampproto
  module Serializer
    # Add common API for serializer
    class JSON
      def self.serialize(message)
        ::JSON.dump(message.marshal)
      end

      def self.deserialize(message)
        ::JSON.parse(message).then { Message.resolve(_1) }
      end
    end
  end
end
