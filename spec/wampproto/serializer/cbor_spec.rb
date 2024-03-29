# frozen_string_literal: true

RSpec.describe Wampproto::Serializer::Cbor do
  let(:serializer) { described_class }
  let(:data) { [Wampproto::Message::Type::HELLO, "realm1", {}] }
  let(:encoded_data) { described_class.encode(data) }

  describe "Msgpack.encode" do
    it "decodes the encoded data" do
      expect(serializer.decode(encoded_data)).to include(Wampproto::Message::Type::HELLO)
    end
  end
end
