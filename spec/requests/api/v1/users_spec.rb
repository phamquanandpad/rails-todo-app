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
end
