# frozen_string_literal: true

RSpec.describe Wampproto::Auth::Ticket do
  subject { described_class.new(secret, authid) }

  let(:authid) { "peter" }
  let(:secret) { "secret!!" }
  let(:challenge) { Wampproto::Message::Challenge.new("ticket", {}) }
  let(:authenticate) { Wampproto::Message::Authenticate.new(secret, {}) }

  describe "#authenticate" do
    context "when challenge is received" do
      let(:response) { described_class.new(secret, authid).authenticate(challenge) }

      it "returns an authenticate message" do
        expect(response).to be_instance_of(Wampproto::Message::Authenticate)
      end

      it "has the correct secret" do
        expect(response.signature).to eq secret
      end
    end
  end
end
