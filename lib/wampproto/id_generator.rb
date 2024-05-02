# frozen_string_literal: true

module Wampproto
  # ID Generator
  class IdGenerator
    MAX_ID = 1 << 53

    @ids = {}
    class << self
      def generate_session_id
        id = rand(100_000..MAX_ID)
        if @ids.include?(id)
          generate_session_id
        else
          @ids[id] = id
        end
      end
    end

    def initialize
      @id = 0
    end

    def next
      if @id == MAX_ID
        @id = 0
      else
        @id += 1
      end
    end
  end
end
