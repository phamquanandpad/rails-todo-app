require "rails_helper"

RSpec.describe "Users", type: :request do
  def auth_headers(user)
    token = Auth::JwtService.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  let(:user)         { create(:user, :with_user_permissions) }
  let(:user_headers) { auth_headers(user) }

  describe "GET /api/v1/users/:id" do
    it "returns the current user" do
      get "/api/v1/users/#{user.id}", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["username"]).to eq(user.username)
      expect(response.parsed_body["email"]).to eq(user.email)
      assert_schema_conform(200)
    end

    it "requires authentication" do
      get "/api/v1/users/#{user.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/users/:id" do
    it "updates the current user" do
      patch "/api/v1/users/#{user.id}",
        params: { username: "user_updated" },
        headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["username"]).to eq("user_updated")
      assert_schema_conform(200)
    end

    it "requires authentication" do
      patch "/api/v1/users/#{user.id}", params: { username: "x" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/users/:id" do
    it "soft-deletes the current user" do
      delete "/api/v1/users/#{user.id}", headers: user_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.reload.deleted_at).not_to be_nil
    end

    it "requires authentication" do
      delete "/api/v1/users/#{user.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  let(:admin)         { create(:user, :with_admin_permissions) }
  let(:admin_headers) { auth_headers(admin) }

  describe "GET /api/v1/users" do
    let!(:other_user) { create(:user, :with_member_permissions, username: "zyxunique") }

    it "returns paginated users for admin" do
      get "/api/v1/users", headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]).to include("page", "limit", "totalPages", "totalCount")
      expect(body["data"].first).to include("id", "username", "email", "role", "permissionsCount")
    end

    it "filters by username prefix with ?q=" do
      get "/api/v1/users?q=zyx", headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      usernames = response.parsed_body["data"].map { _1["username"] }
      expect(usernames).to all(start_with("zyx"))
      expect(usernames).to include("zyxunique")
    end

    it "returns 403 for member" do
      get "/api/v1/users", headers: user_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/users", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/users/:id/update_role" do
    let!(:target_user) { create(:user, :with_member_permissions) }

    it "changes the user role and returns the updated user" do
      patch "/api/v1/users/#{target_user.id}/update_role",
        params: { role: "admin" },
        headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["role"]).to eq("admin")
    end

    it "returns 422 for invalid role" do
      patch "/api/v1/users/#{target_user.id}/update_role",
        params: { role: "superuser" },
        headers: admin_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 403 for member" do
      patch "/api/v1/users/#{target_user.id}/update_role",
        params: { role: "admin" },
        headers: user_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for unknown user" do
      patch "/api/v1/users/999999/update_role",
        params: { role: "admin" },
        headers: admin_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without token" do
      patch "/api/v1/users/#{target_user.id}/update_role",
        params: { role: "admin" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
