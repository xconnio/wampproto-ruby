# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::Cbor do
  let(:serializer) { described_class }
  let(:message) { Wampproto::Message::Hello.new("realm1", {}) }
  let(:serialized_data) { described_class.serialize(message) }

  describe "Msgpack.serialize" do
    it "deserialize the serialize data" do
      expect(serializer.deserialize(serialized_data)).to be_an_instance_of(Wampproto::Message::Hello)
    end
  end
end
