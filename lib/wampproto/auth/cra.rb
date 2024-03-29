# frozen_string_literal: true

require "openssl"
require "base64"

module Wampproto
  module Auth
    # generates wampcra authentication signature
    class Cra < Base
      attr_reader :secret

      AUTH_METHOD = "wampcra"

      def initialize(secret, details = {})
        @secret = Validate.string!("Secret", secret)
        @details = Validate.hash!("Details", details)
        super(AUTH_METHOD, details[:authid], details.fetch(:authextra, {}))
      end

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

        Base64.encode64(hmac.digest).gsub("\n", "")
      end

      def create_drived_secret(extra)
        salt        = extra[:salt]
        length      = extra[:keylen]
        iterations  = extra[:iterations]

        p extra
        p iterations
        p salt
        p length
        p secret

        key = OpenSSL::KDF.pbkdf2_hmac(secret, salt:, iterations:, length:, hash: "SHA256")
        key.unpack1("H*")
      end
    end
  end
end
