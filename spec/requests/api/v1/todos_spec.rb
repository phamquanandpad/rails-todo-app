require "rails_helper"

RSpec.describe "Todos", type: :request do
  def auth_headers(user)
    token = Auth::JwtService.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  let(:user)         { create(:user, :with_member_permissions) }
  let(:norole)           { create(:user) }
  let(:user_headers) { auth_headers(user) }
  let(:norole_headers)   { auth_headers(norole) }

  describe "GET /api/v1/todos" do
    let!(:user_pending) { create(:todo, user: user) }
    let!(:user_deleted) { create(:todo, :soft_deleted, user: user) }
    let!(:norole_todo)      { create(:todo, user: norole) }

    it "returns user's active todos" do
      get "/api/v1/todos", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { _1["id"] }
      expect(ids).to include(user_pending.id)
      expect(ids).not_to include(user_deleted.id)
      expect(ids).not_to include(norole_todo.id)
    end

    it "filters by status" do
      get "/api/v1/todos?status=pending", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.all? { _1["status"] == "pending" }).to be true
    end

    it "requires authentication" do
      get "/api/v1/todos", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/todos/:id" do
    let!(:user_todo)    { create(:todo, user: user) }
    let!(:norole_todo)      { create(:todo, user: norole) }
    let!(:user_deleted) { create(:todo, :soft_deleted, user: user) }

    it "returns a todo owned by current user" do
      get "/api/v1/todos/#{user_todo.id}", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["task"]).to eq(user_todo.task)
    end

    it "returns 404 for another user's todo" do
      get "/api/v1/todos/#{norole_todo.id}", headers: user_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for soft-deleted todo" do
      get "/api/v1/todos/#{user_deleted.id}", headers: user_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/todos" do
    it "creates a new todo" do
      post "/api/v1/todos",
        params: { task: "New task", description: "Details" },
        headers: user_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["task"]).to eq("New task")
      expect(response.parsed_body["status"]).to eq("pending")
    end

    it "fails with missing task" do
      post "/api/v1/todos",
        params: { task: "" },
        headers: user_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/todos/:id" do
    let!(:user_todo) { create(:todo, user: user) }
    let!(:norole_todo)   { create(:todo, user: norole) }

    it "updates the todo" do
      patch "/api/v1/todos/#{user_todo.id}",
        params: { task: "Updated task" },
        headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["task"]).to eq("Updated task")
    end

    it "returns 404 for another user's todo" do
      patch "/api/v1/todos/#{norole_todo.id}",
        params: { task: "Stolen" },
        headers: user_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/todos/:id" do
    let!(:user_todo) { create(:todo, user: user) }
    let!(:norole_todo)   { create(:todo, user: norole) }

    it "soft-deletes the todo" do
      delete "/api/v1/todos/#{user_todo.id}", headers: user_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(user_todo.reload.deleted_at).not_to be_nil
    end

    it "returns 404 for another user's todo" do
      delete "/api/v1/todos/#{norole_todo.id}", headers: user_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
