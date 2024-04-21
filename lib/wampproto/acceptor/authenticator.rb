# frozen_string_literal: true

module Wampproto
  class Acceptor
    # Interface to handle Authentications
    class Authenticator
      class << self
        def authenticate(request)
          raise NotImplementedError
        end
      end
    end
  end
end
