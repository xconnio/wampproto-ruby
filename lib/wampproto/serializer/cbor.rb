# frozen_string_literal: true

require "cbor"

module Wampproto
  module Serializer
    # Add common API for serializer
    class Cbor
      def self.encode(message)
        CBOR.encode(message).unpack("c*")
      end

      def self.decode(message)
        CBOR.decode(message.pack("c*"))
      end
    end
  end
end
