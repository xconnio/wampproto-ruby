# frozen_string_literal: true

RSpec.describe Wampproto::Message::Invocation do
  let(:request_id) { 1 }
  let(:registration_id) { 100 }

  describe ".parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::INVOCATION, request_id, registration_id, {}]
      end

      it { is_expected.to be_an_instance_of(described_class) }
    end

    context "when invalid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::INVOCATION, request_id, "Options"]
      end
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
