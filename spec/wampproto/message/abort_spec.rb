# frozen_string_literal: true

RSpec.describe Wampproto::Message::Abort do
  let(:session_id) { 1234 }

  describe "Abort.parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid data" do
      let(:wamp_message) do
        [Wampproto::Message::Type::ABORT, { message: "The realm does not exist." }, "wamp.error.no_such_realm"]
      end

      it { is_expected.to be_instance_of(described_class) }
    end

    context "when invalid details type" do
      let(:wamp_message) { [Wampproto::Message::Type::ABORT, {}, nil] }
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
