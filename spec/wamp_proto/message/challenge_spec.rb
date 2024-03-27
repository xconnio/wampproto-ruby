# frozen_string_literal: true

RSpec.describe WampProto::Message::Challenge do
  describe "Challenge.parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid data" do
      let(:wamp_message) { [WampProto::Message::Type::CHALLENGE, "ticket", {}] }

      it { is_expected.to be_instance_of(described_class) }
    end

    context "when invalid details type" do
      let(:wamp_message) { [WampProto::Message::Type::CHALLENGE, "ticket", "INVALID TYPE"] }
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
