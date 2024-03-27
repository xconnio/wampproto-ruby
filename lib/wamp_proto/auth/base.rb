# frozen_string_literal: true

module WampProto
  module Auth
    # Auth Base
    class Base
      attr_reader :auth_method, :authid, :auth_extra

      def initialize(method, authid, auth_extra)
        @auth_method = method
        @authid = authid
        @auth_extra = auth_extra
      end

      def authenticate(_challenge)
        raise NotImplementedError
      end
    end
  end
end
