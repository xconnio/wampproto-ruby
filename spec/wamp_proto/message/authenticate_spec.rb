# frozen_string_literal: true

RSpec.describe WampProto::Message::Authenticate do
  let(:session_id) { 1234 }

  describe "Welcome.parse" do
    subject { described_class.parse(wamp_message) }

    context "when valid data" do
      let(:wamp_message) do
        [WampProto::Message::Type::AUTHENTICATE, "secret!!", {}]
      end

      it { is_expected.to be_instance_of(described_class) }
    end

    context "when invalid details type" do
      let(:wamp_message) { [WampProto::Message::Type::AUTHENTICATE, {}, {}] }
      let(:parse) { subject }

      it { expect { parse }.to raise_error(ArgumentError) }
    end
  end
end
