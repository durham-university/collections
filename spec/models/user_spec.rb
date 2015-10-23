require 'rails_helper'

RSpec.describe User, type: :model do
  let(:audituser) { User.audituser }
  let(:batchuser) { User.batchuser }
  it "can create both audit and batch user" do
    # There used to be a bug where only one or the other of these could be
    # created.
    expect(audituser).to be_a User
    expect(batchuser).to be_a User
  end
end
