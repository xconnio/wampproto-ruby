# frozen_string_literal: true

require_relative "wampproto/version"
require_relative "wampproto/validate"
require_relative "wampproto/message"
require_relative "wampproto/serializer"
require_relative "wampproto/auth"
require_relative "wampproto/session_details"
require_relative "wampproto/joiner"

module Wampproto
  class Error < StandardError; end
  # Your code goes here...
end
