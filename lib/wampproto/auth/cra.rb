# frozen_string_literal: true

require "openssl"
require "base64"

module Wampproto
  module Auth
    # generates wampcra authentication signature
    class Cra < Base
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

      private

      def create_signature(challenge)
        extra = challenge.extra
        hmac = OpenSSL::HMAC.new(create_drived_secret(extra), "SHA256") if extra.include?(:salt)
        hmac ||= OpenSSL::HMAC.new(secret, "SHA256")

        hmac.update(extra[:challenge])

        Base64.encode64(hmac.digest).rstrip
      end

      def create_drived_secret(extra)
        salt        = extra[:salt]
        length      = extra[:keylen]
        iterations  = extra[:iterations]

        key = OpenSSL::KDF.pbkdf2_hmac(secret, salt:, iterations:, length:, hash: "SHA256")
        key.unpack1("H*")
      end
    end
  end
end
