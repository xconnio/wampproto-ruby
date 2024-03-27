# frozen_string_literal: true

RSpec.describe WampProto::Message::Goodbye do
  let(:session_id) { 1234 }

  describe "Welcome.parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid data" do
      let(:wamp_message) { [WampProto::Message::Type::GOODBYE, {}, "wamp.close.system_shutdown"] }

      it { is_expected.to be_instance_of(described_class) }
    end

    context "when invalid details type" do
      let(:wamp_message) { [WampProto::Message::Type::GOODBYE, "HELLO", nil] }
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
