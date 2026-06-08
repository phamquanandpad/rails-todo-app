require "rails_helper"

RSpec.describe Auth::JwtService, type: :model do
  it "encodes and decodes a payload" do
    token = Auth::JwtService.encode({ user_id: 42 })
    decoded = Auth::JwtService.decode(token)
    expect(decoded[:user_id]).to eq(42)
  end

  it "returns nil for invalid token" do
    expect(Auth::JwtService.decode("not.a.token")).to be_nil
  end

  it "returns nil for blank token" do
    expect(Auth::JwtService.decode(nil)).to be_nil
    expect(Auth::JwtService.decode("")).to be_nil
  end

  it "returns nil for expired token" do
    token = Auth::JwtService.encode({ user_id: 1 }, exp: -1.hour)
    expect(Auth::JwtService.decode(token)).to be_nil
  end
end
