# frozen_string_literal: true

require "cbor"

module Wampproto
  module Serializer
    # Add common API for serializer
    class Cbor
      def self.serialize(message)
        CBOR.encode(message.marshal).unpack("c*")
      end

      def self.deserialize(message)
        CBOR.decode(message.pack("c*")).then { Message.resolve(_1) }
      end
    end
  end
end
