# frozen_string_literal: true

module WampProto
  module Auth
    # generates wampcra authentication signature
    class Anonymous < Base
      AUTH_METHOD = "anonymous"

      def initialize(details = {})
        @details = Validate.hash!("Details", details)
        super(AUTH_METHOD, details[:authid], details[:auth_extra])
      end

      def details
        {}.tap do |hsh|
          hsh[:authid] = @details.fetch(:authid, "anonymous")
          hsh[:authmethods] = [AUTH_METHOD]
        end
      end
    end
  end
end
