# frozen_string_literal: true

RSpec.describe Wampproto::Auth::Cra do
  subject { described_class.new(secret, authid, authextra) }

  let(:authid) { "peter" }
  let(:secret) { "secret!!" }
  let(:challenge_json) do
    "{ \"nonce\": \"LHRTC9zeOIrt_9U3\",
                \"authprovider\": \"userdb\", \"authid\": \"peter\",
                \"timestamp\": \"2014-06-22T16:36:25.448Z\",
                \"authrole\": \"user\", \"authmethod\": \"wampcra\",
                \"session\": 3251278072152162}"
  end

  let(:authextra) { { challenge: challenge_json } }

  describe "#authenticate" do
    let(:authenticate) { Wampproto::Message::Authenticate.new(secret, {}) }
    let(:challenge) { Wampproto::Message::Challenge.new("wampcra", { challenge: challenge_json }) }

    context "without salt" do
      context "when challenge is received" do
        let(:response) { described_class.new(secret, authid).authenticate(challenge) }

        it "returns an authenticate message" do
          expect(response).to be_instance_of(Wampproto::Message::Authenticate)
        end

        it "has the correct secret" do
          expect(response.signature).to eq "UjsYdWqvtx/GHt9gLsEw4VVqNzGhfxKWkv7+N2sPujs="
        end
      end
    end

    context "with salt" do
      let(:derived_secret) { "c7d2b7e70b1b392feebe93ed6bcc766e8a2260f0d2c77d6b10008dc73132be43" }
      let(:extra) { { salt: "ABC", keylen: 32, iterations: 1000 } }
      let(:challenge) { Wampproto::Message::Challenge.new("wampcra", { challenge: challenge_json }.merge(extra)) }

      context "when challenge is received" do
        let(:response) { described_class.new(secret, authid).authenticate(challenge) }

        it "returns an authenticate message" do
          expect(response).to be_instance_of(Wampproto::Message::Authenticate)
        end

        it "has the correct secret" do
          expect(response.signature).to eq "lo8UnNh/VpxQ4ZNGsgCYh7TArrCv0CnM3JP3BCzlVxM="
        end
      end
    end
  end
end
