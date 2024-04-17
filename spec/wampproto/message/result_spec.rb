# frozen_string_literal: true

RSpec.describe Wampproto::Message::Result do
  let(:request_id) { 1 }

  describe ".parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::RESULT, request_id, {}, [1, 2, 3], { name: "Ismail" }]
      end

      it { is_expected.to be_an_instance_of(described_class) }
    end

    context "when invalid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::RESULT, request_id, "Options", [1, 2, 3], { name: "Ismail" }]
      end
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
