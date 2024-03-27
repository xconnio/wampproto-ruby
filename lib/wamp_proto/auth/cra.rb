# frozen_string_literal: true

module WampProto
  module Auth
    # generates wampcra authentication signature
    class Cra < Base
      attr_reader :secret

      AUTH_METHOD = "wampcra"

      def initialize(secret, details = {})
        @secret = Validate.string!("Secret", secret)
        @details = Validate.hash!("Details", details)
        super(AUTH_METHOD, details[:authid], details[:auth_extra])
      end

      def details
        {}.tap do |hsh|
          hsh[:authid] = @details.fetch(:authid)
          hsh[:authmethods] = [AUTH_METHOD]
          hsh[:authextra] = @details.fetch(:authextra, {})
        end
      end

      def authenticate(challenge)
        signature = create_signature(challenge)
        Message::Authenticate.new(signature)
      end

      private

      def create_signature(challenge)
        extra = challenge.extra
        hmac = OpenSSL::HMAC.new(create_drived_secret(extra), "SHA256") if extra.key?("salt")
        hmac ||= OpenSSL::HMAC.new(secret, "SHA256")

        hmac.update(extra["challenge"])

        Base64.encode64(hmac.digest).gsub("\n", "")
      end

      def create_drived_secret(extra)
        salt        = extra["salt"]
        length      = extra["keylen"]
        iterations  = extra["iterations"]

        key = OpenSSL::KDF.pbkdf2_hmac(secret, salt:, iterations:, length:, hash: "SHA256")
        key.unpack1("H*")
      end
    end
  end
end
