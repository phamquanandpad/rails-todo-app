require "rails_helper"

RSpec.describe "Permissions", type: :request do
  def auth_headers(user)
    token = Auth::JwtService.encode({ user_id: user.id })
    { "Authorization" => "Bearer #{token}" }
  end

  let(:admin)         { create(:user, :with_admin_permissions) }
  let(:member)        { create(:user, :with_member_permissions) }
  let(:admin_headers) { auth_headers(admin) }
  let(:member_headers) { auth_headers(member) }

  describe "GET /api/v1/permissions" do
    let!(:builtin) { Permission.find_or_create_by!(name: "todos:create") }
    let!(:adhoc)   { create(:permission, name: "reports:export") }

    it "returns paginated permissions for admin" do
      get "/api/v1/permissions", headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]).to include("page", "limit", "totalPages", "totalCount")
      assert_schema_conform(200)
    end

    it "filters by name prefix" do
      get "/api/v1/permissions?q=todos", headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      names = response.parsed_body["data"].map { _1["name"] }
      expect(names).to all(start_with("todos"))
    end

    it "prefix match returns empty for a substring-only term" do
      get "/api/v1/permissions?q=odos", headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_empty
    end

    it "returns 403 for member" do
      get "/api/v1/permissions", headers: member_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/permissions", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/permissions/:id" do
    let!(:permission) { Permission.find_or_create_by!(name: "todos:create") }

    it "returns the permission for admin" do
      get "/api/v1/permissions/#{permission.id}", headers: admin_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["name"]).to eq("todos:create")
      expect(body["builtin"]).to be true
      assert_schema_conform(200)
    end

    it "returns 403 for member" do
      get "/api/v1/permissions/#{permission.id}", headers: member_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for unknown id" do
      get "/api/v1/permissions/999999", headers: admin_headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/permissions" do
    it "creates a permission and returns 201" do
      post "/api/v1/permissions",
           params: { name: "reports:export", description: "Export reports as CSV" },
           headers: admin_headers,
           as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["name"]).to eq("reports:export")
      expect(body["builtin"]).to be false
      expect(Permission.exists?(name: "reports:export")).to be true
      assert_schema_conform(201)
    end

    it "returns 422 for a duplicate name" do
      Permission.find_or_create_by!(name: "reports:export")

      post "/api/v1/permissions",
           params: { name: "reports:export" },
           headers: admin_headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for a malformed name" do
      post "/api/v1/permissions",
           params: { name: "Reports Export" },
           headers: admin_headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 403 for member" do
      post "/api/v1/permissions",
           params: { name: "reports:export" },
           headers: member_headers,
           as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/permissions/:id" do
    let!(:permission) { create(:permission, name: "reports:export", description: nil) }

    it "updates the description" do
      patch "/api/v1/permissions/#{permission.id}",
            params: { description: "Export reports as CSV" },
            headers: admin_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["description"]).to eq("Export reports as CSV")
      assert_schema_conform(200)
    end

    it "grants permission to all users of the requested roles" do
      member_user = create(:user, :with_member_permissions)

      patch "/api/v1/permissions/#{permission.id}",
            params: { roles: ["member"] },
            headers: admin_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["roles"]).to include("member")
      expect(member_user.permissions.exists?(id: permission.id)).to be true
    end

    it "revokes permission from users of deselected roles" do
      member_user = create(:user, :with_member_permissions)
      member_user.permissions << permission

      patch "/api/v1/permissions/#{permission.id}",
            params: { roles: [] },
            headers: admin_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["roles"]).to be_empty
      expect(member_user.permissions.exists?(id: permission.id)).to be false
    end

    it "returns 403 for member" do
      patch "/api/v1/permissions/#{permission.id}",
            params: { description: "hacked" },
            headers: member_headers,
            as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/permissions/:id" do
    context "ad-hoc (non-builtin) permission" do
      let!(:permission) { create(:permission, name: "reports:export") }

      it "deletes the permission and cascades grants" do
        user = create(:user)
        user.permissions << permission

        delete "/api/v1/permissions/#{permission.id}", headers: admin_headers, as: :json

        expect(response).to have_http_status(:no_content)
        expect(Permission.exists?(permission.id)).to be false
        expect(UserPermission.exists?(permission_id: permission.id)).to be false
      end
    end

    context "built-in permission" do
      let!(:permission) { Permission.find_or_create_by!(name: "todos:create") }

      it "returns 422 and does not delete the row" do
        delete "/api/v1/permissions/#{permission.id}", headers: admin_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Permission.exists?(permission.id)).to be true
      end
    end

    it "returns 403 for member" do
      permission = create(:permission, name: "reports:export")
      delete "/api/v1/permissions/#{permission.id}", headers: member_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/permissions/:id/users" do
    let!(:permission) { Permission.find_or_create_by!(name: "todos:create") }

    it "returns 200 for admin" do
      get "/api/v1/permissions/#{permission.id}/users", headers: admin_headers, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns 403 for member" do
      get "/api/v1/permissions/#{permission.id}/users", headers: member_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      get "/api/v1/permissions/#{permission.id}/users", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/permissions/:id/users/:user_id" do
    let!(:permission) { create(:permission, name: "reports:export") }

    it "returns 403 for member" do
      post "/api/v1/permissions/#{permission.id}/users/#{member.id}",
        headers: member_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      post "/api/v1/permissions/#{permission.id}/users/#{member.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/permissions/:id/users/:user_id" do
    let!(:permission) { create(:permission, name: "reports:export") }

    it "returns 403 for member" do
      delete "/api/v1/permissions/#{permission.id}/users/#{member.id}",
        headers: member_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      delete "/api/v1/permissions/#{permission.id}/users/#{member.id}", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
