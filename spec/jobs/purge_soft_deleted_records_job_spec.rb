require "rails_helper"

RSpec.describe PurgeSoftDeletedRecordsJob, type: :job do
  describe "#perform" do
    let!(:old_user) { create(:user, deleted_at: 31.days.ago) }
    let!(:old_user_todo) { create(:todo, user: old_user) }
    let!(:old_standalone_todo) { create(:todo, :soft_deleted, deleted_at: 31.days.ago) }
    let!(:recent_user) { create(:user, deleted_at: 1.day.ago) }
    let!(:recent_todo) { create(:todo, :soft_deleted, deleted_at: 1.day.ago) }

    it "purges users and todos beyond 30-day retention" do
      described_class.perform_now

      expect(User.where(id: old_user.id)).not_to exist
      expect(Todo.where(id: old_standalone_todo.id)).not_to exist
    end

    it "cascades user purge to todos" do
      described_class.perform_now
      expect(Todo.where(id: old_user_todo.id)).not_to exist
    end

    it "preserves records within retention window" do
      described_class.perform_now

      expect(User.where(id: recent_user.id)).to exist
      expect(Todo.where(id: recent_todo.id)).to exist
    end

    it "is enqueued on the low queue" do
      expect(described_class.new.queue_name).to eq("low")
    end
  end
end
