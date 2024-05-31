# frozen_string_literal: true

RSpec.describe Wampproto::Dealer do
  let(:session_id) { 123_456 }
  let(:realm) { "realm1" }
  let(:authid) { "peter" }
  let(:authrole) { "user" }
  let(:sessoin_details) { Wampproto::SessionDetails.new(session_id, realm, authid, authrole) }
  let(:request_id) { 1 }
  let(:procedure) { "com.hello.first" }
  let(:dealer) { described_class.new }
  let(:register) { Wampproto::Message::Register.new(request_id, {}, procedure) }

  context "when session is added" do
    before { dealer.add_session(sessoin_details) }

    context "when procedure is registered" do
      subject { register_response.message }

      let(:register_response) { dealer.receive_message(session_id, register) }

      it { is_expected.to be_instance_of Wampproto::Message::Registered }

      context "when second procedure is registered" do
        subject { register_2_response.message }

        let(:second_procedure) { "com.second.procedure" }
        let(:register_2_response) { dealer.receive_message(session_id, register2) }
        let(:register2) { Wampproto::Message::Register.new(request_id + 1, {}, second_procedure) }

        before { register_response } # registers first procedure

        it { is_expected.to be_an_instance_of Wampproto::Message::Registered }

        context "when unregister both procedures" do
          let(:unregister_first) do
            Wampproto::Message::Unregister.new(request_id + 2, register_response.message.registration_id)
          end

          let(:unregister_second) do
            Wampproto::Message::Unregister.new(request_id + 3, register_2_response.message.registration_id)
          end

          before do
            register_2_response
            dealer.receive_message(session_id, unregister_first)
          end

          it "does not give any error" do
            expect(dealer.receive_message(session_id, unregister_second).message)
              .to be_an_instance_of(Wampproto::Message::Unregistered)
          end
        end
      end

      context "when session unregisters a procedure" do
        subject { unregister_response.message }

        let(:unregister) do
          Wampproto::Message::Unregister.new(request_id + 1, register_response.message.registration_id)
        end

        let(:unregister_response) { dealer.receive_message(session_id, unregister) }

        it { is_expected.to be_instance_of Wampproto::Message::Unregistered }

        context "when registration not found" do
          let(:unregister) { Wampproto::Message::Unregister.new(request_id + 1, 9999) }

          it { is_expected.to be_instance_of Wampproto::Message::Error }
        end
      end

      context "when call message is received from caller_id" do
        subject { call_response.message }

        before do
          register_response
          dealer.add_session(caller_session_details)
        end

        let(:caller_id) { 456_789 }
        let(:realm) { "realm1" }
        let(:authid) { "alex" }
        let(:authrole) { "user" }
        let(:caller_session_details) { Wampproto::SessionDetails.new(caller_id, realm, authid, authrole) }
        let(:call) { Wampproto::Message::Call.new(request_id, { disclose_me: true }, procedure, 1) }
        let(:call_response) { dealer.receive_message(caller_id, call) }

        it { is_expected.to be_instance_of Wampproto::Message::Invocation }

        it "has caller identifiers" do
          expect(call_response.message.details).to include(:caller)
        end

        context "when progressive call is made" do
          let(:args) { [2020, 2021, 2022, 2023] }
          let(:progressive_call) do
            Wampproto::Message::Call.new(request_id, { receive_progress: true }, procedure, args)
          end
          let(:call_response) { dealer.receive_message(caller_id, progressive_call) }

          it { is_expected.to be_instance_of Wampproto::Message::Invocation }

          it "sends progressive call result" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
            call_response
            args.each_with_index do |_year, index|
              progress_yield = Wampproto::Message::Yield.new(request_id + 1, { progress: true }, index + 1)
              msg = dealer.receive_message(session_id, progress_yield).message
              expect(msg).to be_instance_of(Wampproto::Message::Result)
              expect(msg.details).to include(:progress)
            end
            progress_yield = Wampproto::Message::Yield.new(request_id + 1, {})
            msg = dealer.receive_message(session_id, progress_yield).message
            expect(msg).to be_instance_of(Wampproto::Message::Result)
            expect(msg.details).not_to include(:progress)
          end
        end

        context "when calling unregistered procedure" do
          let(:call) { Wampproto::Message::Call.new(request_id, {}, "invalid.procedure", 1) }

          it { is_expected.to be_instance_of Wampproto::Message::Error }
        end

        context "when yield message received from the callee" do
          subject { yield_response.message }

          before { call_response }

          let(:yield_msg) { Wampproto::Message::Yield.new(request_id + 1, {}, 2) }
          let(:yield_response) { dealer.receive_message(session_id, yield_msg) }

          it { is_expected.to be_instance_of Wampproto::Message::Result }

          context "when session is removed" do
            subject { dealer.registrations_by_session }

            before do
              dealer.remove_session(session_id)
              dealer.remove_session(caller_id)
            end

            it { is_expected.to be_empty }

            context "when session does not exists" do
              it { expect { dealer.remove_session(caller_id) }.to raise_exception(KeyError) }
            end
          end
        end
      end
    end
  end
end
