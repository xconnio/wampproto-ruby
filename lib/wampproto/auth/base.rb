# frozen_string_literal: true

module Wampproto
  module Auth
    # Auth Base
    class Base
      attr_reader :authmethod, :authid, :authextra

      def initialize(method, authid, authextra)
        @authmethod = method
        @authid = authid
        @authextra = authextra
      end

      def authenticate(_challenge)
        raise NotImplementedError
      end
    end
  end
end
