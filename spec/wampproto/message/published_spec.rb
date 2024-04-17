# frozen_string_literal: true

RSpec.describe Wampproto::Message::Published do
  let(:request_id) { 1 }
  let(:publication_id) { 100 }

  describe ".parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::PUBLISHED, request_id, publication_id]
      end

      it { is_expected.to be_an_instance_of(described_class) }
    end

    context "when invalid message" do
      let(:wamp_message) do
        [Wampproto::Message::Type::PUBLISHED, request_id, "should be publicaiton integer", "wamp.error"]
      end
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
