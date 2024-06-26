# frozen_string_literal: true

module Wampproto
  module Message
    # published message
    class Published < Base
      attr_reader :request_id, :publication_id

      def initialize(request_id, publication_id)
        super()
        @request_id     = Validate.int!("Request Id", request_id)
        @publication_id = Validate.int!("Publication Id", publication_id)
      end

      def marshal
        [Type::PUBLISHED, request_id, publication_id]
      end

      def self.parse(wamp_message)
        _type, request_id, publication_id = Validate.length!(wamp_message, 3)
        new(request_id, publication_id)
      end
    end
  end
end
