# frozen_string_literal: true

RSpec.describe Wampproto::Broker do
  let(:session_id) { 123_456 }
  let(:request_id) { 1 }
  let(:topic) { "com.hello.first" }
  let(:broker) { described_class.new }
  let(:subscribe) { Wampproto::Message::Subscribe.new(request_id, {}, topic) }

  context "when session is added" do
    before { broker.add_session(session_id) }

    context "when topic is subscribed" do
      subject { subscribe_response.message }

      let(:subscribe_response) { broker.receive_message(session_id, subscribe) }

      it { is_expected.to be_instance_of Wampproto::Message::Subscribed }

      context "when second session subscribes to topic" do
        subject { next_subscribe_response.message }

        let(:subscription_id) { subscribe_response.message.subscription_id }
        let(:next_subscription_id) { next_subscribe_response.message.subscription_id }
        let(:next_session_id) { 445_666 }
        let(:next_subscribe) { Wampproto::Message::Subscribe.new(request_id, {}, topic) }
        let(:next_subscribe_response) { broker.receive_message(next_session_id, next_subscribe) }

        before do
          broker.add_session(next_session_id)
          subscribe_response
        end

        it { is_expected.to be_instance_of Wampproto::Message::Subscribed }

        it "share the same subscription_id" do
          expect(subscription_id).to eq(next_subscription_id)
        end
      end

      context "when topic is unsubscribed" do
        subject { unsubscribe_response.message }

        before { subscribe_response }

        let(:unsubscribe) do
          Wampproto::Message::Unsubscribe.new(request_id + 1, subscribe_response.message.subscription_id)
        end

        let(:unsubscribe_response) { broker.receive_message(session_id, unsubscribe) }

        it { is_expected.to be_an_instance_of Wampproto::Message::Unsubscribed }
      end

      context "when topic is published" do
        let(:publisher_id) { 333 }

        before { broker.add_session(publisher_id) }

        context "when acknowledge option is passed" do
          subject { publish_response }

          let(:publish) { Wampproto::Message::Publish.new(request_id, { acknowledge: true }, topic) }
          let(:publish_response) { broker.receive_message(publisher_id, publish) }

          before { subscribe_response }

          it { is_expected.to be_instance_of Array }

          it "includes two messages" do
            expect(publish_response.length).to eq 2
          end
        end

        context "when acknowledge option is missing" do
          subject { publish_response }

          let(:publish) { Wampproto::Message::Publish.new(request_id, {}, topic) }
          let(:publish_response) { broker.receive_message(publisher_id, publish) }

          before { subscribe_response }

          it { is_expected.to be_instance_of Array }

          it "includes two messages" do
            expect(publish_response.length).to eq 1
          end
        end
      end
    end
  end
end
