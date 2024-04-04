# frozen_string_literal: true

RSpec.describe Wampproto::Joiner do
  context "when Anonymous authenticator" do
    let(:joiner) { described_class.new("realm") }

    context "when hello is sent" do
      before { joiner.send_hello }

      it "state should be HELLO_SENT" do
        expect(joiner.state).to eq Wampproto::Joiner::STATE_HELLO_SENT
      end

      context "when welcome is received" do
        before { joiner.receive(message) }

        let(:session_id) { 12_345 }
        let(:welcome) { Wampproto::Message::Welcome.new(session_id) }
        let(:message) { Wampproto::Serializer::JSON.serialize(welcome) }

        it "state should be JOINED" do
          expect(joiner.state).to eq Wampproto::Joiner::STATE_JOINED
        end
      end
    end

    context "when welcome is received before hello is sent" do
      let(:session_id) { 12_345 }
      let(:welcome) { Wampproto::Message::Welcome.new(session_id) }
      let(:message) { Wampproto::Serializer::JSON.serialize(welcome) }

      it "is protocol violation" do
        expect { joiner.receive(message) }.to raise_error(Wampproto::ProtocolViolation)
      end
    end
  end

  context "when Ticket authenticator" do
    let(:authid) { "peter" }
    let(:secret) { "secret!!" }
    let(:authenticator) { Wampproto::Auth::Ticket.new(secret, authid) }
    let(:joiner) { described_class.new("realm", Wampproto::Serializer::JSON, authenticator) }

    context "when hello is sent" do
      before { joiner.send_hello }

      it "state should be HELLO_SENT" do
        expect(joiner.state).to eq Wampproto::Joiner::STATE_HELLO_SENT
      end

      context "when challenge is received" do
        subject { Wampproto::Serializer::JSON.deserialize(sent_message) }

        let(:challenge) { Wampproto::Message::Challenge.new("ticket", { autid: authid }) }
        let(:received_message) { Wampproto::Serializer::JSON.serialize(challenge) }
        let(:sent_message) { joiner.receive(received_message) }

        it { is_expected.to be_an_instance_of(Wampproto::Message::Authenticate) }
      end

      context "when authenticate is sent" do
        before { joiner.receive(received_message) }

        let(:challenge) { Wampproto::Message::Challenge.new("ticket", { autid: authid }) }
        let(:received_message) { Wampproto::Serializer::JSON.serialize(challenge) }

        it "state should be AUTHENTICATE_SENT" do
          expect(joiner.state).to eq Wampproto::Joiner::STATE_AUTHENTICATE_SENT
        end

        context "when welcome is received" do
          before { joiner.receive(message) }

          let(:session_id) { 12_345 }
          let(:welcome) { Wampproto::Message::Welcome.new(session_id) }
          let(:message) { Wampproto::Serializer::JSON.serialize(welcome) }

          it "state should be JOINED" do
            expect(joiner.state).to eq Wampproto::Joiner::STATE_JOINED
          end
        end
      end
    end
  end
end
