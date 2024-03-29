# frozen_string_literal: true

require "msgpack"

module Wampproto
  module Serializer
    # Add common API for serializer
    class Msgpack
      def self.encode(message)
        ::MessagePack.pack(message).unpack("c*")
      end

      def self.decode(message)
        ::MessagePack.unpack(message.pack("c*"))
      end
    end
  end
end
