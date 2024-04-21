# frozen_string_literal: true

module Wampproto
  module Message
    # Wamp Hello message
    class Hello < Base
      attr_reader :realm, :details

      def initialize(realm, details = {})
        super()
        @realm = Validate.string!("Realm", realm)
        @details = default_details.merge(parse_details(Validate.hash!("Details", details))).merge(additional_details)
      end

      def marshal
        [Type::HELLO, @realm, @details]
      end

      def parse_details(hsh = {})
        details = {}
        details[:roles] = hsh.fetch(:roles, default_roles)
        details[:authid] = hsh.fetch(:authid, nil)
        details[:authmethods] = [*hsh.fetch(:authmethods, "anonymous")]
        details[:authextra] = Validate.hash!("AuthExtra", hsh.fetch(:authextra)) if hsh[:authextra]
        details
      end

      def self.parse(wamp_message)
        _type, realm, details = wamp_message
        new(realm, details)
      end

      def roles
        @roles ||= details.fetch(:roles, {})
      end

      def authid
        @authid ||= details[:authid]
      end

      def authmethods
        @authmethods ||= details.fetch(:authmethods, [])
      end

      def authextra
        @authextra ||= details.fetch(:authextra, {})
      end

      private

      def default_details
        { roles: default_roles }
      end

      def default_roles
        { caller: {}, publisher: {}, subscriber: {}, callee: {} }
      end

      def additional_details
        { agent: "Ruby-Wamp-Client-#{Wampproto::VERSION}" }
      end
    end
  end
end
