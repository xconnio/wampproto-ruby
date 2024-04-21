# frozen_string_literal: true

require "ed25519"

module Wampproto
  module Auth
    # generates wampcra authentication signature
    class Cryptosign < Base
      include Helpers

      attr_reader :private_key
      attr_accessor :channel_id

      AUTH_METHOD = "cryptosign"

      def initialize(private_key, authid, authextra = {})
        @private_key = Validate.string!("Private Key", private_key)
        super(AUTH_METHOD, authid, authextra)
      end

      def authenticate(challenge)
        signature = self.class.create_signature(private_key, challenge.extra[:challenge], channel_id)
        Message::Authenticate.new(signature)
      end

      class << self
        def create_challenge
          binary_challenge = SecureRandom.random_bytes(32)
          binary_to_hex(binary_challenge)
        end

        def verify_challenge(signature, msg, public_key)
          verify_key = Ed25519::VerifyKey.new(hex_to_binary(public_key))

          binary_signature = hex_to_binary(signature)
          signature = binary_signature[0, 64].to_s
          message = binary_signature[64, 32].to_s
          return false if message.empty? || signature.empty?
          return false if msg != binary_to_hex(message)

          verify_key.verify(signature, message)
        end

        def sign_challenge(private_key, challenge, channel_id = nil)
          create_signature(private_key, challenge, channel_id)
        end

        def create_signature(private_key, challenge, channel_id = nil)
          return handle_channel_binding(private_key, challenge, channel_id) if channel_id

          handle_without_channel_binding(private_key, challenge)
        end

        def handle_without_channel_binding(private_key, hex_challenge)
          key_pair = Ed25519::SigningKey.new(hex_to_binary(private_key))

          binary_challenge  = hex_to_binary(hex_challenge)
          binary_signature  = key_pair.sign(binary_challenge)
          signature         = binary_to_hex(binary_signature)

          "#{signature}#{hex_challenge}"
        end

        def handle_channel_binding(private_key, hex_challenge, channel_id)
          key_pair = Ed25519::SigningKey.new(hex_to_binary(private_key))

          channel_id              = hex_to_binary(channel_id)
          challenge               = hex_to_binary(hex_challenge)
          xored_challenge         = xored_strings(channel_id, challenge)
          binary_signed_challenge = key_pair.sign(xored_challenge)
          signature               = binary_to_hex(binary_signed_challenge)
          hex_xored_challenge     = binary_to_hex(xored_challenge)
          "#{signature}#{hex_xored_challenge}"
        end

        def xored_strings(channel_id, challenge_str)
          channel_id_bytes = channel_id.bytes
          challenge_bytes = challenge_str.bytes
          # Added || 0 like (byte1 || 0) to make steep check happy
          xored = channel_id_bytes.zip(challenge_bytes).map { |byte1, byte2| (byte1 || 0) ^ (byte2 || 0) }
          xored.pack("C*")
        end
      end
    end
  end
end
