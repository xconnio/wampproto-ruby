# frozen_string_literal: true

RSpec.describe Wampproto::Message::Error do
  let(:request_id) { 1 }

  describe ".parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::ERROR, Wampproto::Message::Type::CALL, request_id, { message: "error" },
         "wamp.error"]
      end

      it { is_expected.to be_an_instance_of(described_class) }
    end

    context "when invalid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::ERROR, Wampproto::Message::Type::CALL, request_id, "should be a hash",
         "wamp.error"]
      end
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
