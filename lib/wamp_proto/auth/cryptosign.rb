# frozen_string_literal: true

require "ed25519"

module WampProto
  module Auth
    # generates wampcra authentication signature
    class Cryptosign < Base
      attr_reader :private_key

      AUTH_METHOD = "cryptosign"

      def initialize(private_key, details = {})
        @private_key = Validate.string!("Private Key", private_key)
        @details = Validate.hash!("Details", details)
        super(AUTH_METHOD, details[:authid], details[:auth_extra])
      end

      def details
        {}.tap do |hsh|
          hsh[:authid] = @details.fetch(:authid)
          hsh[:authmethods] = [AUTH_METHOD]
          hsh[:authextra] = @details.fetch(:authextra, {}).merge(pubkey: public_key)
        end
      end

      def authenticate(challenge)
        signature = create_signature(challenge)
        Message::Authenticate.new(signature)
      end

      def create_challenge
        binary_challenge = SecureRandom.random_bytes(32)
        binary_challenge.unpack1("H*")
      end

      def verify_challenge(signature, msg)
        binary_signature = hex_to_binary(signature)
        signature = binary_signature[0, 64]
        message = binary_signature[64, 32]
        return false if msg != message.unpack1("H*")

        key_pair.verify_key.verify(signature, message)
      end

      private

      def key_pair
        @key_pair ||= Ed25519::SigningKey.new(hex_to_binary(private_key))
      end

      def public_key
        binary_to_hex(key_pair.verify_key.to_bytes)
      end

      def create_signature(challenge)
        extra = challenge.extra
        return handle_channel_binding(extra) if extra[:channel_id]

        handle_without_channel_binding(extra)
      end

      def handle_without_channel_binding(extra)
        hex_challenge     = extra[:challenge]
        binary_challenge  = hex_to_binary(hex_challenge)
        binary_signature  = key_pair.sign(binary_challenge)
        signature         = binary_to_hex(binary_signature)

        "#{signature}#{hex_challenge}"
      end

      def handle_channel_binding(extra)
        channel_id              = hex_to_binary(extra[:channel_id])
        challenge               = hex_to_binary(extra[:challenge])
        xored_challenge         = xored_strings(channel_id, challenge)
        binary_signed_challenge = key_pair.sign(xored_challenge)
        signature               = binary_to_hex(binary_signed_challenge)
        hex_xored_challenge     = binary_to_hex(xored_challenge)
        "#{signature}#{hex_xored_challenge}"
      end

      def xored_strings(channel_id, challenge_str)
        channel_id_bytes = channel_id.bytes
        challenge_bytes = challenge_str.bytes
        xored = channel_id_bytes.zip(challenge_bytes).map { |byte1, byte2| byte1 ^ byte2 }
        xored.pack("C*")
      end

      def hex_to_binary(hex_string)
        [hex_string].pack("H*")
      end

      def binary_to_hex(binary_string)
        binary_string.unpack1("H*")
      end
    end
  end
end
