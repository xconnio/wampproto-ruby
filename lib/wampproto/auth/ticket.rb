# frozen_string_literal: true

module Wampproto
  module Auth
    # generates ticket authentication signature
    class Ticket < Base
      AUTH_METHOD = "ticket"
      attr_reader :secret

      def initialize(secret, details = {})
        @details = Validate.hash!("Details", details)
        @secret = Validate.string!("Secret", secret)
        super(AUTH_METHOD, details[:authid], details[:authextra])
      end

      def details
        {}.tap do |hsh|
          hsh[:authid] = details.fetch(:authid)
          hsh[:authmethods] = [AUTH_METHOD]
          hsh[:authextra] = details.fetch(:authextra, {})
        end
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
