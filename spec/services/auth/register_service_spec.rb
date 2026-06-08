require "rails_helper"

RSpec.describe Auth::RegisterService do
  describe "#call" do
    it "registers a new user and returns user info" do
      result = Auth::RegisterService.call(
        username: "newuser",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(result).to be_success
      expect(result.data[:user][:username]).to eq("newuser")
    end

    it "fails with duplicate email" do
      create(:user, email: "existinguser@example.com")

      result = Auth::RegisterService.call(
        username: "otheruser",
        email: "existinguser@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(result).to be_failure
      expect(result.errors).not_to be_empty
    end

    it "fails with missing username" do
      result = Auth::RegisterService.call(
        username: "",
        email: "new@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(result).to be_failure
    end

    it "fails when passwords do not match" do
      result = Auth::RegisterService.call(
        username: "newuser2",
        email: "newuser2@example.com",
        password: "password123",
        password_confirmation: "different"
      )

      expect(result).to be_failure
    end
  end
end
