# frozen_string_literal: true

require "msgpack"

module Wampproto
  module Serializer
    # Add common API for serializer
    class Msgpack
      def self.serialize(message)
        ::MessagePack.pack(message.marshal).unpack("c*")
      end

      def self.deserialize(message)
        ::MessagePack.unpack(message.pack("c*")).then { Message.resolve(_1) }
      end
    end
  end
end
