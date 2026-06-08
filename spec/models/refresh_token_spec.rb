require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  let(:user) { create(:user) }

  it "valid scope excludes expired tokens" do
    valid_token   = create(:refresh_token, user: user)
    expired_token = create(:refresh_token, :expired, user: user)

    valid_ids = RefreshToken.valid.pluck(:id)
    expect(valid_ids).to include(valid_token.id)
    expect(valid_ids).not_to include(expired_token.id)
  end

  it "valid scope excludes revoked tokens" do
    revoked_token = create(:refresh_token, :revoked, user: user)

    valid_ids = RefreshToken.valid.pluck(:id)
    expect(valid_ids).not_to include(revoked_token.id)
  end

  describe "#expired?" do
    context "with expired token" do
      it "returns true" do
        token = create(:refresh_token, :expired, user: user)
        expect(token).to be_expired
      end
    end
    context "with valid token" do
      it "returns false" do
        token = create(:refresh_token, user: user)
        expect(token).not_to be_expired
      end
    end
  end

  describe "#revoke!" do
    it "sets deleted_at" do
      token = create(:refresh_token, user: user)
      expect(token.deleted_at).to be_nil
      token.revoke!
      expect(token.reload.deleted_at).not_to be_nil
    end
  end

  it "belongs to user" do
    token = create(:refresh_token, user: user)
    expect(token.user).to eq(user)
  end
end
