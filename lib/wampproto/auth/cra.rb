# frozen_string_literal: true

require "openssl"
require "base64"
require "time"

module Wampproto
  module Auth
    # generates wampcra authentication signature
    class Cra < Base
      include Helpers

      attr_reader :secret

      AUTH_METHOD = "wampcra"

      # rubocop:disable Metrics/ParameterLists
      def initialize(secret, authid, authextra = {}, salt = nil, keylen = 32, iterations = 100)
        @secret     = Validate.string!("Secret", secret)
        @salt       = Validate.string!("Salt", salt) if salt
        @keylen     = Validate.int!("Keylen", keylen) if salt
        @iterations = Validate.int!("Iterations", iterations) if salt
        super(AUTH_METHOD, authid, authextra)
      end
      # rubocop:enable Metrics/ParameterLists

      def authenticate(challenge)
        signature = create_signature(challenge)
        Message::Authenticate.new(signature)
      end

      class << self
        def create_challenge(session_id, authid, authrole, authprovider)
          nounce = binary_to_hex(SecureRandom.random_bytes(16))
          {
            authid: authid,
            authrole: authrole,
            authprovider: authprovider,
            nounce: nounce,
            authmethod: AUTH_METHOD,
            session_id: session_id,
            timestamp: Time.now.utc.iso8601(3)
          }.to_json
        end

        # rubocop:disable Metrics/ParameterLists
        def verify_challenge(signature, challenge, secret, salt = nil, keylen = 32, iterations = 100)
          encoded_challenge = sign_challenge(secret, challenge, salt, keylen, iterations)
          signature == encoded_challenge
        end
        # rubocop:enable Metrics/ParameterLists

        def sign_challenge(secret, challenge, salt = nil, keylen = 32, iterations = 100)
          unless salt.nil?
            hmac = OpenSSL::HMAC.new(
              create_derive_secret(secret, salt, keylen, iterations),
              "SHA256"
            )
          end
          hmac ||= OpenSSL::HMAC.new(secret, "SHA256")

          hmac.update(challenge)

          Base64.encode64(hmac.digest).rstrip
        end

        def create_derive_secret(secret, salt, length, iterations)
          key = OpenSSL::KDF.pbkdf2_hmac(secret, salt: salt, iterations: iterations, length: length, hash: "SHA256")
          binary_to_hex(key)
        end
      end

      private

      def create_signature(challenge)
        extra = challenge.extra

        self.class.sign_challenge(
          secret, extra[:challenge], extra[:salt], extra[:keylen], extra[:iterations]
        )
      end
    end
  end
end
