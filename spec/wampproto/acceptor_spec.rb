# frozen_string_literal: true

RSpec.describe Wampproto::Acceptor do
  let(:acceptor) { described_class.new }
  let(:realm) { "realm1" }

  describe "#receive" do
    subject { Wampproto::Serializer::JSON.deserialize(receive_hello.first) }

    let(:serialized_received_message) { serialized_hello }
    let(:receive_hello) { acceptor.receive(serialized_received_message) }
    let(:welcome?) { receive_hello.last }
    let(:serialized_hello) { Wampproto::Serializer::JSON.serialize(hello) }

    context "when no authmethod is sent in hello" do
      before { allow(acceptor.authenticator).to receive(:authenticate) }

      let(:hello) { Wampproto::Message::Hello.new("realm1", {}) }

      it { is_expected.to be_instance_of(Wampproto::Message::Welcome) }

      context "when subject is :welcome?" do
        subject { welcome? }

        it { is_expected.to be_truthy }
      end

      context 'when subject is "state"' do
        subject { acceptor.state }

        before { receive_hello }

        it { is_expected.to eq Wampproto::Acceptor::STATE_WELCOME_SENT }

        it "is accepted" do
          expect(acceptor).to be_accepted
        end
      end
    end

    context "when 'ticket' authmethod is sent in hello message" do
      let(:secret) { "Secret!!" }
      let(:hello) { Wampproto::Message::Hello.new("realm1", { authmethods: ["ticket"], authid: "peter" }) }
      let(:request) { Wampproto::Acceptor::Request.new(hello) }
      let(:response) { Wampproto::Acceptor::Response.new("peter", "admin", secret) }

      before { allow(acceptor.authenticator).to receive(:authenticate).and_return(response) }

      it { is_expected.to be_instance_of(Wampproto::Message::Challenge) }

      context 'when subject is "state"' do
        subject { acceptor.state }

        before { receive_hello }

        it { is_expected.to eq Wampproto::Acceptor::STATE_CHALLENGE_SENT }
      end

      context "when authenticate message is received" do
        subject { Wampproto::Serializer::JSON.deserialize(receive_authenticate.first) }

        let(:authenticate) { Wampproto::Message::Authenticate.new(secret) }
        let(:serialized_authenticate) { Wampproto::Serializer::JSON.serialize(authenticate) }
        let(:receive_authenticate) { acceptor.receive(serialized_authenticate) }

        # receives hello
        before do
          receive_hello
          receive_authenticate
        end

        it { is_expected.to be_an_instance_of(Wampproto::Message::Welcome) }

        context "when invalid token" do
          let(:authenticate) { Wampproto::Message::Authenticate.new("wrong-ticket") }

          it { is_expected.to be_an_instance_of(Wampproto::Message::Abort) }
        end
      end
    end

    context "when cryptosign" do
      let(:public_key) { "8930373ada588a83ce2a0748c58af02c9e31d45636a478166b52d1acbd73bba3" }
      let(:private_key) { "6dd9663f4530b13207ff98780a6003dd7bff81447c0b617bb4fa1793c5d99816" }
      let(:hello_details) { { authmethods: ["cryptosign"], authid: "peter", authextra: { pubkey: public_key } } }
      let(:hello) { Wampproto::Message::Hello.new("realm1", hello_details) }
      let(:request) { Wampproto::Acceptor::Request.new(hello) }
      let(:response) { Wampproto::Acceptor::Response.new("peter", "admin", public_key) }

      before { allow(acceptor.authenticator).to receive(:authenticate).and_return(response) }

      it { is_expected.to be_instance_of(Wampproto::Message::Challenge) }

      context "when authenticate is received" do
        subject { Wampproto::Serializer::JSON.deserialize(receive_authenticate.first) }

        let(:challenge) { Wampproto::Serializer::JSON.deserialize(receive_hello.first) }

        let(:signature) { Wampproto::Auth::Cryptosign.sign_challenge(private_key, challenge.extra[:challenge]) }
        let(:authenticate) { Wampproto::Message::Authenticate.new(signature) }
        let(:serialized_authenticate) { Wampproto::Serializer::JSON.serialize(authenticate) }
        let(:receive_authenticate) { acceptor.receive(serialized_authenticate) }

        it { is_expected.to be_an_instance_of(Wampproto::Message::Welcome) }

        context "when invalid signature" do
          before { challenge } # so complete the flow

          let(:authenticate) { Wampproto::Message::Authenticate.new("I a not a valid") }

          it { is_expected.to be_an_instance_of(Wampproto::Message::Abort) }
        end
      end
    end

    context "when wampcra" do
      let(:secret) { "Secret!!" }
      let(:hello_details) { { authmethods: ["wampcra"], authid: "peter" } }
      let(:hello) { Wampproto::Message::Hello.new("realm1", hello_details) }
      let(:request) { Wampproto::Acceptor::Request.new(hello) }
      let(:response) { Wampproto::Acceptor::Response.new("peter", "admin", secret) }

      before { allow(acceptor.authenticator).to receive(:authenticate).and_return(response) }

      it { is_expected.to be_instance_of(Wampproto::Message::Challenge) }

      context "when authenticate is received" do
        subject { Wampproto::Serializer::JSON.deserialize(receive_authenticate.first) }

        let(:challenge) { Wampproto::Serializer::JSON.deserialize(receive_hello.first) }

        let(:signature) { Wampproto::Auth::Cra.sign_challenge(secret, challenge.extra[:challenge]) }
        let(:authenticate) { Wampproto::Message::Authenticate.new(signature) }
        let(:serialized_authenticate) { Wampproto::Serializer::JSON.serialize(authenticate) }
        let(:receive_authenticate) { acceptor.receive(serialized_authenticate) }

        it { is_expected.to be_an_instance_of(Wampproto::Message::Welcome) }

        context "when invalid signature" do
          before { challenge } # so complete the flow

          let(:authenticate) { Wampproto::Message::Authenticate.new("I a not a valid") }

          it { is_expected.to be_an_instance_of(Wampproto::Message::Abort) }
        end
      end
    end
  end
end
