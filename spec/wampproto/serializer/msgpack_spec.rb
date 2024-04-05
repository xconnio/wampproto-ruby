# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::Msgpack do
  let(:serializer) { described_class }
  let(:message) { Wampproto::Message::Hello.new("realm1", {}) }
  let(:serialized_data) { described_class.serialize(message) }

  describe "Msgpack.serialize" do
    it "deserialized the serialized data" do
      expect(serializer.deserialize(serialized_data)).to be_instance_of(Wampproto::Message::Hello)
    end
  end
end
