require "rails_helper"

RSpec.describe Auth::RefreshTokenService, type: :model do
  let(:user)          { create(:user) }
  let!(:valid_token)   { create(:refresh_token, user: user) }
  let!(:expired_token) { create(:refresh_token, :expired, user: user) }
  let!(:revoked_token) { create(:refresh_token, :revoked, user: user) }

  describe "#call" do
    context "with valid refresh token" do
      it "returns new tokens" do
        result = Auth::RefreshTokenService.call(
          refresh_token: valid_token.token
        )

        expect(result).to be_success
        expect(result.data[:accessToken]).not_to be_nil
        expect(result.data[:refreshToken]).not_to be_nil
      end

      it "rotates the refresh token" do
        old_token_value = valid_token.token
        result = Auth::RefreshTokenService.call(
          refresh_token: old_token_value
        )

        expect(result.data[:refreshToken]).not_to eq(old_token_value)
        expect(RefreshToken.valid.find_by(token: old_token_value)).to be_nil
      end
    end

    context "with invalid refresh token" do
      it "fails for expired refresh token" do
        result = Auth::RefreshTokenService.call(
          refresh_token: expired_token.token
        )

        expect(result).to be_failure
      end

      it "fails for revoked refresh token" do
        result = Auth::RefreshTokenService.call(
          refresh_token: revoked_token.token
        )

        expect(result).to be_failure
      end

      it "fails for blank token" do
        result = Auth::RefreshTokenService.call(
          refresh_token: nil
        )

        expect(result).to be_failure
      end
    end
  end
end
