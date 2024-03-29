# frozen_string_literal: true

module Wampproto
  module Auth
    # generates ticket authentication signature
    class Ticket < Base
      AUTH_METHOD = "ticket"
      attr_reader :secret

      def initialize(secret, authid, authextra = {})
        @secret = Validate.string!("Secret", secret)
        super(AUTH_METHOD, authid, authextra)
      end

      def authenticate(challenge)
        signature = create_signature(challenge)
        Message::Authenticate.new(signature)
      end

      private

      def create_signature(_challenge)
        secret
      end
    end
  end
end
