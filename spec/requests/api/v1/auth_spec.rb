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
      assert_schema_conform(201)
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
      assert_schema_conform(200)
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
      assert_schema_conform(200)
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

  describe "GET /api/v1/auth/me" do
    let(:member) { create(:user, :with_member_permissions) }
    let(:admin)  { create(:user, :with_admin_permissions) }

    it "returns 401 without a token" do
      get "/api/v1/auth/me", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an invalid token" do
      get "/api/v1/auth/me",
        headers: { "Authorization" => "Bearer invalid.token.here" },
        as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a soft-deleted user" do
      member.update!(deleted_at: Time.current)
      get "/api/v1/auth/me", headers: auth_headers(member), as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the member's profile and permissions" do
      get "/api/v1/auth/me", headers: auth_headers(member), as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(member.id)
      expect(body["username"]).to eq(member.username)
      expect(body["email"]).to eq(member.email)
      expect(body["role"]).to eq("member")
      expect(body["permissions"]).to match_array(AppConstants::Roles::PERMISSIONS[:member])
      assert_schema_conform(200)
    end

    it "returns the admin's profile and permissions" do
      get "/api/v1/auth/me", headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["role"]).to eq("admin")
      expect(body["permissions"]).to match_array(AppConstants::Roles::PERMISSIONS[:admin])
    end

    it "reflects permission revocation without caching" do
      get "/api/v1/auth/me", headers: auth_headers(member), as: :json
      expect(response.parsed_body["permissions"]).not_to be_empty

      member.user_permissions.destroy_all

      get "/api/v1/auth/me", headers: auth_headers(member), as: :json
      expect(response.parsed_body["permissions"]).to be_empty
    end
  end
end
