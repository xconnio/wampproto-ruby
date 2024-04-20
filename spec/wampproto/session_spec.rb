# frozen_string_literal: true

RSpec.describe Wampproto::Session do
  let(:procedure) { "com.hello.world" }
  let(:topic) { "com.hello.world" }
  let(:request_id) { 1 }
  let(:next_request_id) { 2 }
  let(:session) { described_class.new }

  describe "CALL flow" do
    let(:call_message) { Wampproto::Message::Call.new(request_id, {}, procedure) }
    let(:result_message) { Wampproto::Message::Result.new(request_id, {}, ["hello"]) }

    context "when result is received" do
      subject { session.receive_message(result_message) }

      context "when call message was sent" do
        before { session.send_message(call_message) }

        it { is_expected.to be_instance_of Wampproto::Message::Result }
      end

      context "when call message was not sent" do
        it { expect { session.receive_message(result_message) }.to raise_exception(StandardError) }
      end
    end
  end

  describe "REGISTER flow" do
    let(:registration_id) { 100 }
    let(:register_message) { Wampproto::Message::Register.new(request_id, {}, procedure) }
    let(:registered_message) { Wampproto::Message::Registered.new(request_id, registration_id) }

    context "when registered is received" do
      subject { session.receive_message(registered_message) }

      context "when register message was sent" do
        before { session.send_message(register_message) }

        it { is_expected.to be_an_instance_of Wampproto::Message::Registered }

        context "when unregister message was sent" do
          subject { session.receive_message(unregistered_message) }

          let(:unregister_message) { Wampproto::Message::Unregister.new(next_request_id, registration_id) }
          let(:unregistered_message) { Wampproto::Message::Unregistered.new(next_request_id) }

          before do
            session.receive_message(registered_message)
            session.send_message(unregister_message)
          end

          it { is_expected.to be_instance_of(Wampproto::Message::Unregistered) }
        end
      end

      context "when register message was NOT sent" do
        it { expect { session.receive_message(result_message) }.to raise_exception(StandardError) }
      end
    end
  end

  describe "SUBSCRIBE flow" do
    let(:subscription_id) { 100 }
    let(:subscribe_message) { Wampproto::Message::Subscribe.new(request_id, {}, topic) }
    let(:subscribed_message) { Wampproto::Message::Subscribed.new(request_id, subscription_id) }

    context "when subscribed is received" do
      subject { session.receive_message(subscribed_message) }

      context "when subscribe message was sent" do
        before { session.send_message(subscribe_message) }

        it { is_expected.to be_an_instance_of Wampproto::Message::Subscribed }

        context "when unsubscribed message was sent" do
          subject { session.receive_message(unsubscribed_message) }

          let(:unsubscribe_message) { Wampproto::Message::Unsubscribe.new(next_request_id, subscription_id) }
          let(:unsubscribed_message) { Wampproto::Message::Unsubscribed.new(next_request_id) }

          before do
            session.receive_message(subscribed_message)
            session.send_message(unsubscribe_message)
          end

          it { is_expected.to be_instance_of(Wampproto::Message::Unsubscribed) }
        end
      end

      context "when subscribe message was NOT sent" do
        it { expect { session.receive_message(subscribed_message) }.to raise_exception(StandardError) }
      end
    end
  end

  describe "PUBLISH flow" do
    let(:options) { {} }
    let(:publication_id) { 100 }
    let(:publish_message) { Wampproto::Message::Publish.new(request_id, options, topic, 1) }
    let(:published_message) { Wampproto::Message::Published.new(request_id, publication_id) }

    context "when published is received" do
      subject { session.receive_message(published_message) }

      context "when options.acknowledge is NOT sent" do
        it { expect { session.receive_message(published_message) }.to raise_exception(StandardError) }
      end

      context "when option.acknowledge is sent" do
        before { session.send_message(publish_message) }

        let(:options) { { acknowledge: true } }

        it { is_expected.to be_an_instance_of(Wampproto::Message::Published) }
      end
    end
  end

  describe "INVOCATION flow" do
    let(:registration_id) { 100 }
    let(:register_message) { Wampproto::Message::Register.new(request_id, {}, procedure) }
    let(:registered_message) { Wampproto::Message::Registered.new(request_id, registration_id) }
    let(:invocation_message) { Wampproto::Message::Invocation.new(next_request_id, registration_id, {}, 2) }
    let(:yield_message) { Wampproto::Message::Yield.new(next_request_id, {}, [2]) }

    context "when procedure is registered" do
      before do
        session.send_message(register_message)
        session.receive_message(registered_message)
      end

      context "when invocation message is received" do
        before { session.receive_message(invocation_message) }

        it { expect { session.send_message(yield_message) }.not_to raise_error }
      end

      context "when yield message is sent WITHOUT invocation" do
        it { expect { session.send_message(yield_message) }.to raise_error(StandardError) }
      end
    end

    context "when procedure is NOT registered" do
      context "when invocation message is received" do
        it { expect { session.receive_message(invocation_message) }.to raise_exception(StandardError) }
      end
    end
  end
end
