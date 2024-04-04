# frozen_string_literal: true

module Wampproto
  module Auth
    # anonymous authentication
    class Anonymous < Base
      AUTH_METHOD = "anonymous"

      def initialize(authid = "", authextra = {})
        super(AUTH_METHOD, authid, authextra)
      end
    end
  end
end
