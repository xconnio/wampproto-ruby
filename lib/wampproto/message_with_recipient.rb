# frozen_string_literal: true

module Wampproto
  # handler class for dealer and broker responses
  class MessageWithRecipient
    attr_reader :message, :recipient

    def initialize(message, recipient)
      @message = message
      @recipient = recipient
    end
  end
end
