# frozen_string_literal: true

module Wampproto
  # ID Generator
  class IdGenerator
    MAX_ID = 1 << 53

    class << self
      def generate_session_id
        rand(1..MAX_ID)
      end
    end

    def initialize
      @id = 0
    end

    def next
      @id = 0 if @id == MAX_ID
      @id += 1
    end
  end
end
