require "rails_helper"

RSpec.describe "Notifications", type: :request do
  def auth_headers(user)
    token = Auth::JwtService.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  let(:user)         { create(:user, :with_member_permissions) }
  let(:other_user)   { create(:user, :with_member_permissions) }
  let(:user_headers) { auth_headers(user) }

  describe "GET /api/v1/notifications" do
    let!(:n1) { create(:notification, user: user, title: "First") }
    let!(:n2) { create(:notification, :read, user: user, title: "Second") }
    let!(:other) { create(:notification, user: other_user, title: "Other") }

    it "returns only the current user's notifications" do
      get "/api/v1/notifications", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["data"].map { _1["id"] }
      expect(ids).to include(n1.id, n2.id)
      expect(ids).not_to include(other.id)
      assert_schema_conform(200)
    end

    it "returns notifications in recent order" do
      get "/api/v1/notifications", headers: user_headers, as: :json

      ids = response.parsed_body["data"].map { _1["id"] }
      expect(ids.first).to eq(n2.id)
      assert_schema_conform(200)
    end

    it "includes pagination meta" do
      get "/api/v1/notifications", headers: user_headers, as: :json

      meta = response.parsed_body["meta"]
      expect(meta).to include("page", "limit", "totalPages", "totalCount")
      assert_schema_conform(200)
    end

    it "requires authentication" do
      get "/api/v1/notifications", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/notifications/:id/read" do
    let!(:notification) { create(:notification, user: user) }

    it "marks the notification as read" do
      patch "/api/v1/notifications/#{notification.id}/read", headers: user_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(notification.reload.read?).to be true
    end

    it "returns 404 for another user's notification" do
      other_notification = create(:notification, user: other_user)

      patch "/api/v1/notifications/#{other_notification.id}/read", headers: user_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      patch "/api/v1/notifications/#{notification.id}/read", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/notifications/read_all" do
    let!(:n1) { create(:notification, user: user) }
    let!(:n2) { create(:notification, user: user) }
    let!(:other) { create(:notification, user: other_user) }

    it "marks all current user's notifications as read" do
      post "/api/v1/notifications/read_all", headers: user_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.notifications.unread.count).to eq(0)
    end

    it "does not touch other users' notifications" do
      post "/api/v1/notifications/read_all", headers: user_headers, as: :json

      expect(other.reload.read?).to be false
    end

    it "requires authentication" do
      post "/api/v1/notifications/read_all", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
