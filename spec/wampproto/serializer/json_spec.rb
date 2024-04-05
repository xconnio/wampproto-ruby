# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::JSON do
  let(:serializer) { described_class }
  let(:message) { Wampproto::Message::Hello.new("realm1", {}) }

  describe "JSON.serialize" do
    it "serializes" do
      expect(serializer.serialize(message)).to eq JSON.dump(message.marshal)
    end
  end

  describe "JSON.deserialize" do
    let(:serialized_data) { JSON.dump(message.marshal) }

    it "deserializes" do
      expect(serializer.deserialize(serialized_data)).to be_instance_of(Wampproto::Message::Hello)
    end
  end
end
