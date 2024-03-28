# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::JSON do
  let(:serializer) { described_class }
  let(:data) { [Wampproto::Message::Type::HELLO, "realm1", {}] }

  describe "JSON.encode" do
    it "encodes" do
      expect(serializer.encode(data)).to eq JSON.dump(data)
    end
  end

  describe "JSON.decode" do
    let(:serialized_data) { JSON.dump(data) }

    it "decodes" do
      expect(serializer.decode(serialized_data)).to include(Wampproto::Message::Type::HELLO)
    end
  end
end
