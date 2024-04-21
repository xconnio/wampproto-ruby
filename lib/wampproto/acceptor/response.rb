# frozen_string_literal: true

module Wampproto
  class Acceptor
    # Request object sent for authentication
    class Response
      attr_reader :authid, :authrole, :secret

      def initialize(authid, authrole, secret = nil)
        @authid   = authid
        @authrole = authrole
        @secret   = secret
      end

      alias ticket secret
      alias public_key secret
    end
  end
end
