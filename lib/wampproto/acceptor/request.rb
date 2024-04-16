# frozen_string_literal: true

require "forwardable"

module Wampproto
  class Acceptor
    # Request object sent for authentication
    class Request
      extend Forwardable

      attr_reader :realm, :authid, :authextra, :hello

      def initialize(hello)
        @hello = hello
      end

      def authmethod
        @hello.authmethods[0].to_s.intern
      end

      def public_key
        @hello.authextra.fetch(:public_key)
      end

      def secret
        nil
      end

      def ticket
        nil
      end

      def_delegators :@hello, :authid, :realm, :authextra, :authmethods
    end

    # AuthenticateRequest
    class AuthenticateRequest < Request
      extend Forwardable
      attr_reader :authenticate

      def initialize(authenticate, hello_request)
        @authenticate = authenticate
        @hello_request = hello_request
        super(hello_request.hello)
      end

      def ticket
        @authenticate.signature
      end

      def secret
        @authenticate.signature
      end

      def_delegators :@hello_request, :authmethod, :authid, :realm, :authextra, :authmethods
    end
  end
end
