# frozen_string_literal: true

RSpec.describe Wampproto::Broker do
  let(:session_id) { 123_456 }
  let(:realm) { "realm1" }
  let(:authid) { "peter" }
  let(:authrole) { "user" }
  let(:sessoin_details) { Wampproto::SessionDetails.new(session_id, realm, authid, authrole) }
  let(:request_id) { 1 }
  let(:topic) { "com.hello.first" }
  let(:broker) { described_class.new }
  let(:subscribe) { Wampproto::Message::Subscribe.new(request_id, {}, topic) }

  context "when session is added" do
    before { broker.add_session(sessoin_details) }

    context "when topic is subscribed" do
      subject { subscribe_response.message }

      let(:subscribe_response) { broker.receive_message(session_id, subscribe) }

      it { is_expected.to be_instance_of Wampproto::Message::Subscribed }

      context "when second session subscribes to topic" do
        subject { next_subscribe_response.message }

        let(:subscription_id) { subscribe_response.message.subscription_id }
        let(:next_subscription_id) { next_subscribe_response.message.subscription_id }
        let(:next_session_id) { 445_666 }
        let(:next_authid) { "Joe" }
        let(:next_session_details) { Wampproto::SessionDetails.new(next_session_id, realm, next_authid, authrole) }
        let(:next_subscribe) { Wampproto::Message::Subscribe.new(request_id, {}, topic) }
        let(:next_subscribe_response) { broker.receive_message(next_session_id, next_subscribe) }

        before do
          broker.add_session(next_session_details)
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
        let(:realm) { "realm1" }
        let(:authid) { "alex" }
        let(:authrole) { "user" }
        let(:publisher_session) { Wampproto::SessionDetails.new(publisher_id, realm, authid, authrole) }
        let(:publisher_id) { 333 }

        before { broker.add_session(publisher_session) }

        context "when acknowledge and disclose_me options are passed" do
          subject { publish_response }

          let(:publish) { Wampproto::Message::Publish.new(request_id, { acknowledge: true, disclose_me: true }, topic) }
          let(:publisher_event) { publish_response.find { |obj| obj.message.respond_to?(:details) } }
          let(:publish_response) { broker.receive_message(publisher_id, publish) }

          before { subscribe_response }

          it { is_expected.to be_instance_of Array }

          it "includes two messages" do
            expect(publish_response.length).to eq 2
          end

          it "includes publisher information" do
            expect(publisher_event.message.details).to include(:publisher)
          end
        end

        context "when acknowledge option is missing" do
          subject { publish_response }

          let(:publish) { Wampproto::Message::Publish.new(request_id, {}, topic) }
          let(:publish_response) { broker.receive_message(publisher_id, publish) }

          before { subscribe_response }

          it { is_expected.to be_instance_of Array }

          it "includes only subscriber message" do
            expect(publish_response.length).to eq 1
          end

          context "when exclude_me options is false" do
            let(:publish) { Wampproto::Message::Publish.new(request_id, { exclude_me: false }, topic) }
            let(:publisher_subscribe_response) { broker.receive_message(publisher_id, subscribe) }

            before { publisher_subscribe_response }

            it "includes message for both subscriber and publisher" do
              expect(publish_response.length).to eq 2
            end
          end
        end
      end
    end
  end
end
