# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::Msgpack do
  let(:serializer) { described_class }
  let(:data) { [Wampproto::Message::Type::HELLO, "realm1", {}] }
  let(:serialized_data) { described_class.serialize(data) }

  describe "Msgpack.serialize" do
    it "deserialized the serialized data" do
      expect(serializer.deserialize(serialized_data)).to include(Wampproto::Message::Type::HELLO)
    end
  end
end
