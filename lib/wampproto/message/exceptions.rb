# frozen_string_literal: true

module Wampproto
  module Message
    module Exceptions
      INVALID_DATA_TYPE_ERROR = "%<message>s: value at index %<index>s must be of type '%<expected_type>s'" \
                                "but was %<actual_type>s"
      INVALID_RANGE_ERROR = "%<message>s: value at index %<index>s must be between '%<start>s' and '%<end>s" \
                            "but was %<actual>s"
      INVALID_DETAIL_ERROR = "%<message>s: value at index %<index>s for key '%<key>s' must be of type" \
                             "'%<expected_type>s' but was %<actual_type>s"
    end
  end
end
