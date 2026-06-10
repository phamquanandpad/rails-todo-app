require "rails_helper"

RSpec.describe Maintenance::PurgeUsersService do
  let(:cutoff) { 30.days.ago }

  describe "#call" do
    context "when there are users soft-deleted beyond the cutoff" do
      let!(:old_user) { create(:user, deleted_at: 31.days.ago) }
      let!(:old_user_active_todo)  { create(:todo, user: old_user) }
      let!(:old_user_deleted_todo) { create(:todo, :soft_deleted, user: old_user) }
      let!(:refresh_token) { create(:refresh_token, user: old_user) }

      it "archives the user into archived_users" do
        described_class.new(cutoff).call
        expect(ArchivedUser.where(original_id: old_user.id)).to exist
      end

      it "hard-deletes the user from users" do
        described_class.new(cutoff).call
        expect(User.where(id: old_user.id)).not_to exist
      end

      it "archives all todos (active and deleted) into archived_todos" do
        described_class.new(cutoff).call
        expect(ArchivedTodo.where(original_id: old_user_active_todo.id)).to exist
        expect(ArchivedTodo.where(original_id: old_user_deleted_todo.id)).to exist
      end

      it "hard-deletes all todos" do
        described_class.new(cutoff).call
        expect(Todo.where(user_id: old_user.id)).not_to exist
      end

      it "hard-deletes refresh tokens" do
        described_class.new(cutoff).call
        expect(RefreshToken.where(user_id: old_user.id)).not_to exist
      end

      it "returns success with purged count" do
        result = described_class.new(cutoff).call
        expect(result).to be_success
        expect(result.data[:purged]).to eq(1)
      end
    end

    context "when users are soft-deleted within the retention window" do
      let!(:recent_user) { create(:user, deleted_at: 29.days.ago) }

      it "does not archive them" do
        described_class.new(cutoff).call
        expect(ArchivedUser.where(original_id: recent_user.id)).not_to exist
        expect(User.where(id: recent_user.id)).to exist
      end
    end

    context "when users are active" do
      let!(:active_user) { create(:user) }

      it "does not archive them" do
        described_class.new(cutoff).call
        expect(ArchivedUser.where(original_id: active_user.id)).not_to exist
        expect(User.where(id: active_user.id)).to exist
      end
    end

    context "when a user has user_permissions" do
      let!(:old_user) { create(:user, :with_member_permissions, deleted_at: 31.days.ago) }

      it "hard-deletes user_permissions" do
        described_class.new(cutoff).call
        expect(UserPermission.where(user_id: old_user.id)).not_to exist
      end
    end
  end
end
