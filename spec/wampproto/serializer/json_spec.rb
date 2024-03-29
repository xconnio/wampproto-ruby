# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::JSON do
  let(:serializer) { described_class }
  let(:data) { [Wampproto::Message::Type::HELLO, "realm1", {}] }

  describe "JSON.serialize" do
    it "serializes" do
      expect(serializer.serialize(data)).to eq JSON.dump(data)
    end
  end

  describe "JSON.deserialize" do
    let(:serialized_data) { JSON.dump(data) }

    it "deserializes" do
      expect(serializer.deserialize(serialized_data)).to include(Wampproto::Message::Type::HELLO)
    end
  end
end
