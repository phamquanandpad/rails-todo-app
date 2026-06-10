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
      ids = response.parsed_body["data"].map { _1["id"] }
      expect(ids).to include(user_pending.id)
      expect(ids).not_to include(user_deleted.id)
      expect(ids).not_to include(norole_todo.id)
      assert_schema_conform(200)
    end

    it "filters by status" do
      get "/api/v1/todos?status=pending", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].all? { _1["status"] == "pending" }).to be true
    end

    it "requires authentication" do
      get "/api/v1/todos", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    context "pagination" do
      let!(:todos) { create_list(:todo, 3, user: user) }

      it "returns meta with pagination info" do
        get "/api/v1/todos", headers: user_headers, as: :json

        meta = response.parsed_body["meta"]
        expect(meta["page"]).to eq(1)
        expect(meta["limit"]).to eq(20)
        expect(meta["totalPages"]).to eq(1)
        expect(meta["totalCount"]).to eq(4)
      end

      it "paginates results with limit and page" do
        get "/api/v1/todos?limit=2&page=1", headers: user_headers, as: :json

        body = response.parsed_body
        expect(body["data"].size).to eq(2)
        expect(body["meta"]["totalPages"]).to eq(2)
      end

      it "returns the second page" do
        get "/api/v1/todos?limit=2&page=2", headers: user_headers, as: :json

        body = response.parsed_body
        expect(body["data"].size).to eq(2)
        expect(body["meta"]["page"]).to eq(2)
      end
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
      assert_schema_conform(200)
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
      assert_schema_conform(201)
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
      assert_schema_conform(200)
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

  describe "GET /api/v1/todos/deleted" do
    let!(:deleted_todo)  { create(:todo, :soft_deleted, user: user) }
    let!(:active_todo)   { create(:todo, user: user) }
    let!(:other_deleted) { create(:todo, :soft_deleted, user: norole) }

    it "returns current user's soft-deleted todos" do
      get "/api/v1/todos/deleted", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["data"].map { _1["id"] }
      expect(ids).to include(deleted_todo.id)
      expect(ids).not_to include(active_todo.id)
      expect(ids).not_to include(other_deleted.id)
      assert_schema_conform(200)
    end

    it "includes pagination meta" do
      get "/api/v1/todos/deleted", headers: user_headers, as: :json

      meta = response.parsed_body["meta"]
      expect(meta).to include("page", "limit", "totalPages", "totalCount")
    end

    it "requires authentication" do
      get "/api/v1/todos/deleted", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "forbids a user without the todos:deleted permission" do
      get "/api/v1/todos/deleted", headers: norole_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/todos/:id/restore" do
    let!(:deleted_todo)  { create(:todo, :soft_deleted, user: user) }
    let!(:active_todo)   { create(:todo, user: user) }
    let!(:other_deleted) { create(:todo, :soft_deleted, user: norole) }

    it "restores a soft-deleted todo" do
      patch "/api/v1/todos/#{deleted_todo.id}/restore", headers: user_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(deleted_todo.id)
      expect(deleted_todo.reload.deleted_at).to be_nil
      assert_schema_conform(200)
    end

    it "returns 404 for an active todo" do
      patch "/api/v1/todos/#{active_todo.id}/restore", headers: user_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for another user's deleted todo" do
      patch "/api/v1/todos/#{other_deleted.id}/restore", headers: user_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      patch "/api/v1/todos/#{deleted_todo.id}/restore", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "forbids a user without the todos:restore permission" do
      norole_todo = create(:todo, :soft_deleted, user: norole)
      patch "/api/v1/todos/#{norole_todo.id}/restore", headers: norole_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
