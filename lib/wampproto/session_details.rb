# frozen_string_literal: true

module Wampproto
  # Session Details
  class SessionDetails
    attr_reader :session_id, :realm, :authid, :authrole

    def initialize(session_id, realm, authid, authrole)
      @session_id = session_id
      @realm = realm
      @authid = authid
      @authrole = authrole
    end

    def ==(other)
      return false unless other.instance_of?(SessionDetails)

      session_id == other.session_id &&
        realm == other.realm &&
        authid == other.authid &&
        authrole == other.authrole
    end
  end
end
