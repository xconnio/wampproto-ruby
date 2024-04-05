# frozen_string_literal: true

RSpec.describe Wampproto::Auth::Cryptosign do
  subject { described_class.new(private_key, authid, {}) }

  let(:authid) { "peter" }
  let(:private_key) { "4d57d97a68f555696620a6d849c0ce582568518d729eb753dc7c732de2804510" }
  let(:challenge_str) { "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" }

  describe "#authenticate" do
    let(:challenge) do
      Wampproto::Message::Challenge.new("cryptosign", { challenge: challenge_str, channel_binding: })
    end

    context "without channel_binding" do
      let(:channel_binding) { nil }
      # rubocop:disable Layout/LineLength
      let(:signature) do
        "b32675b221f08593213737bef8240e7c15228b07028e19595294678c90d11c0cae80a357331bfc5cc9fb71081464e6e75013517c2cf067ad566a6b7b728e5d03ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
      end
      # rubocop:enable Layout/LineLength

      context "when challenge is received" do
        let(:response) { described_class.new(private_key, authid).authenticate(challenge) }

        it "returns an authenticate message" do
          expect(response).to be_instance_of(Wampproto::Message::Authenticate)
        end

        it "has the correct private_key" do
          expect(response.signature).to eq signature
        end
      end
    end

    context "with channel_binding" do
      let(:channel_binding) { "tls-unique" }
      let(:channel_id) { "62e935ae755f3d48f80d4d59f6121358c435722a67e859cc0caa8b539027f2ff" }
      # rubocop:disable Layout/LineLength
      let(:signature) do
        "9b6f41540c9b95b4b7b281c3042fa9c54cef43c842d62ea3fd6030fcb66e70b3e80d49d44c29d1635da9348d02ec93f3ed1ef227dfb59a07b580095c2b82f80f9d16ca518aa0c2b707f2b2a609edeca73bca8dd59817a633f35574ac6fd80d00"
      end
      # rubocop:enable Layout/LineLength

      let(:challenge) do
        Wampproto::Message::Challenge.new("cryptosign", { challenge: challenge_str, channel_binding: })
      end

      context "when challenge is received" do
        let(:authenticator) { described_class.new(private_key, authid) }
        let(:response) { authenticator.authenticate(challenge) }

        it "returns an authenticate message" do
          expect(response).to be_instance_of(Wampproto::Message::Authenticate)
        end

        it "has the correct secret" do
          allow(authenticator).to receive(:channel_id).and_return(channel_id)
          expect(response.signature).to eq signature
        end
      end
    end
  end

  describe "Cryptosign.verify_challenge" do
    subject { described_class.verify_challenge(authenticate.signature, challenge_msg, public_key) }

    let(:challenge_msg) { described_class.create_challenge }
    let(:challenge) { Wampproto::Message::Challenge.new("cryptosign", { challenge: challenge_msg }) }
    let(:public_key) { "1adfc8bfe1d35616e64dffbd900096f23b066f914c8c2ffbb66f6075b96e116d" }
    let(:authenticator) { described_class.new(private_key, authid, {}) }
    let(:authenticate) { authenticator.authenticate(challenge) }

    context "when valid signature" do
      it { is_expected.to be_truthy }
    end

    context "when invalid signature" do
      let(:authenticate) { Wampproto::Message::Authenticate.new("invalid-signature") }

      it { is_expected.to be_falsey }
    end
  end
end
