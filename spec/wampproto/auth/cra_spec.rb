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

  describe "Cra.verify_challenge" do
    subject { described_class.verify_challenge(authenticate.signature, challenge_msg, secret) }

    let(:session_id) { 1 }
    let(:challenge_msg) { described_class.create_challenge(session_id, authid, "role", "dbprovider") }
    let(:challenge) { Wampproto::Message::Challenge.new("cryptosign", { challenge: challenge_msg }) }
    let(:authenticator) { described_class.new(secret, authid, { challenge: challenge_msg }) }
    let(:authenticate) { authenticator.authenticate(challenge) }

    context "when valid signature" do
      it { is_expected.to be_truthy }
    end

    context "when invalid signature" do
      let(:authenticate) { Wampproto::Message::Authenticate.new("invalid-signature") }

      it { is_expected.to be_falsey }
    end

    context "when secret is salted" do
      subject do
        described_class.verify_challenge(authenticate.signature, challenge_msg, secret, salt, keylen, iterations)
      end

      let(:challenge) do
        Wampproto::Message::Challenge.new(
          "cryptosign", {
            challenge: challenge_msg,
            salt:,
            keylen:,
            iterations:
          }
        )
      end

      let(:salt) { "salty" }
      let(:keylen) { 32 }
      let(:iterations) { 1000 }
      let(:derived_secret) { described_class.create_derive_secret(secret, salt, keylen, iterations) }

      context "when valid signature" do
        it { is_expected.to be_truthy }
      end

      context "when invalid signature" do
        let(:authenticate) { Wampproto::Message::Authenticate.new("invalid-signature") }

        it { is_expected.to be_falsey }

        context "when salt does not matches" do
          subject do
            described_class.verify_challenge(authenticate.signature, challenge_msg, secret, "invalid-salt", keylen,
                                             iterations)
          end

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
