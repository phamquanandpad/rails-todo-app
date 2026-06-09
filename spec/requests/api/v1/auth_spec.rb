require "rails_helper"

RSpec.describe "Auth", type: :request do
  def auth_headers(user)
    token = Auth::JwtService.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  describe "POST /api/v1/auth/register" do
    it "creates user and returns success" do
      post "/api/v1/auth/register", params: {
        username: "newuser", email: "newuser@example.com",
        password: "password123", password_confirmation: "password123"
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["username"]).to eq("newuser")
      expect(response.parsed_body["email"]).to eq("newuser@example.com")
    end

    it "fails with invalid params" do
      post "/api/v1/auth/register", params: {
        username: "", email: "bad", password: "123", password_confirmation: "456"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "user@example.com", password: "password123") }

    it "returns tokens for valid credentials" do
      post "/api/v1/auth/login", params: {
        email: user.email, password: "password123"
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("accessToken")
      expect(body).to have_key("refreshToken")
    end

    it "fails with wrong password" do
      post "/api/v1/auth/login", params: {
        email: user.email, password: "wrongpass"
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let!(:user)         { create(:user) }
    let!(:refresh_token) { create(:refresh_token, user: user) }

    it "returns new tokens" do
      post "/api/v1/auth/refresh", params: {
        refreshToken: refresh_token.token
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("accessToken")
      expect(body).to have_key("refreshToken")
    end

    it "fails with invalid token" do
      post "/api/v1/auth/refresh", params: { refreshToken: "bogus" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let!(:user)         { create(:user) }
    let!(:refresh_token) { create(:refresh_token, user: user) }

    it "revokes refresh token" do
      delete "/api/v1/auth/logout",
        params: { refreshToken: refresh_token.token },
        headers: auth_headers(user),
        as: :json

      expect(response).to have_http_status(:no_content)
    end
  end
end
