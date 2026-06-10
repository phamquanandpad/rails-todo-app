require "rails_helper"

RSpec.describe Maintenance::PurgeTodosService do
  let(:cutoff) { 30.days.ago }

  describe "#call" do
    context "when there are todos soft-deleted beyond the cutoff" do
      let!(:old_todo) { create(:todo, :soft_deleted, deleted_at: 31.days.ago) }
      let!(:old_todo2) { create(:todo, :soft_deleted, deleted_at: 60.days.ago) }

      it "archives them into archived_todos" do
        described_class.new(cutoff).call

        expect(ArchivedTodo.where(original_id: old_todo.id)).to exist
        expect(ArchivedTodo.where(original_id: old_todo2.id)).to exist
      end

      it "hard-deletes them from todos" do
        described_class.new(cutoff).call

        expect(Todo.where(id: old_todo.id)).not_to exist
        expect(Todo.where(id: old_todo2.id)).not_to exist
      end

      it "returns success with purged count" do
        result = described_class.new(cutoff).call

        expect(result).to be_success
        expect(result.data[:purged]).to eq(2)
      end

      it "copies the correct fields" do
        described_class.new(cutoff).call

        archived = ArchivedTodo.find_by!(original_id: old_todo.id)
        expect(archived.user_id).to eq(old_todo.user_id)
        expect(archived.task).to eq(old_todo.task)
        expect(archived.status).to eq(old_todo.status)
        expect(archived.deleted_at).to be_within(1.second).of(old_todo.deleted_at)
        expect(archived.archived_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context "when todos are soft-deleted within the retention window" do
      let!(:recent_todo) { create(:todo, :soft_deleted, deleted_at: 29.days.ago) }

      it "does not archive them" do
        described_class.new(cutoff).call
        expect(ArchivedTodo.where(original_id: recent_todo.id)).not_to exist
      end

      it "leaves them in todos" do
        described_class.new(cutoff).call
        expect(Todo.where(id: recent_todo.id)).to exist
      end
    end

    context "when todos are active (not soft-deleted)" do
      let!(:active_todo) { create(:todo) }

      it "does not archive them" do
        described_class.new(cutoff).call
        expect(ArchivedTodo.where(original_id: active_todo.id)).not_to exist
        expect(Todo.where(id: active_todo.id)).to exist
      end
    end
  end
end
