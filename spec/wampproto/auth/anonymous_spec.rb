# frozen_string_literal: true

RSpec.describe Wampproto::Auth::Anonymous do
  it "creates an instance of auth anonymous" do
    expect(described_class.new("")).to be_instance_of(described_class)
  end
end
