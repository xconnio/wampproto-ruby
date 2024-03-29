# frozen_string_literal: true

module Wampproto
  module Auth
    # generates ticket authentication signature
    class Ticket < Base
      AUTH_METHOD = "ticket"
      attr_reader :secret

      def initialize(secret, details = {})
        Validate.hash!("Details", details)
        @secret = Validate.string!("Secret", secret)
        super(AUTH_METHOD, details[:authid], details.fetch(:authextra, {}))
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
