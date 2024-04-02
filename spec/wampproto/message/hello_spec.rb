# frozen_string_literal: true

RSpec.describe Wampproto::Message::Hello do
  describe "Hello.parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid input" do
      let(:wamp_message) { [1, "realm", { roles: { publisher: {}, subscriber: {} } }] }

      it { is_expected.to be_instance_of(described_class) }
    end

    context "when invalid input" do
      context "when roles is invalid type" do
        let(:wamp_message) { [1, "realm", ""] }
        let(:parse_call) { subject }

        it { expect { parse_call }.to raise_error(ArgumentError) }
      end
    end
  end
end
