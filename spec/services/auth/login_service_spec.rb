require "rails_helper"

RSpec.describe Auth::LoginService, type: :model do
  let!(:user)        { create(:user, email: "user@example.com", password: "password123") }
  let!(:deleted_user) { create(:user, :soft_deleted, email: "deleted_user@example.com", password: "password123") }

  describe "#call" do
    context "with valid credentials" do
      it "logs in successfully" do
        result = Auth::LoginService.call(email: user.email, password: "password123")

        expect(result).to be_success
        expect(result.data[:accessToken]).not_to be_nil
        expect(result.data[:refreshToken]).not_to be_nil
        expect(result.data[:user][:username]).to eq(user.username)
      end
    end

    context "with invalid credentials" do
      it "fails with wrong password" do
        result = Auth::LoginService.call(email: user.email, password: "wrongpass")

        expect(result).to be_failure
        expect(result.errors).to eq("Invalid email or password")
      end

      it "fails with unknown email" do
        result = Auth::LoginService.call(email: "nobody@example.com", password: "password123")

        expect(result).to be_failure
      end

      it "fails for soft-deleted user" do
        result = Auth::LoginService.call(email: deleted_user.email, password: "password123")

        expect(result).to be_failure
      end
    end
  end
end
