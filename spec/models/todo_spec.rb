require "rails_helper"

RSpec.describe Todo, type: :model do
  let(:owner) { create(:user) }
  subject(:todo) { create(:todo, user: owner) }

  it "is valid" do
    expect(todo).to be_valid
  end

  it "requires task" do
    todo.task = nil
    expect(todo).not_to be_valid
    expect(todo.errors[:task]).to include("can't be blank")
  end

  it "enforces task maximum length" do
    todo.task = "a" * 256
    expect(todo).not_to be_valid
  end

  it "has pending status by default" do
    expect(todo).to be_pending
  end

  it "supports in_progress status" do
    todo.status = :in_progress
    expect(todo).to be_in_progress
  end

  it "supports completed status" do
    todo.status = :completed
    expect(todo).to be_completed
  end

  it "belongs to user" do
    expect(todo).to respond_to(:user)
    expect(todo.user).to eq(owner)
  end

  it "active scope excludes soft-deleted todos" do
    active_todo  = create(:todo, user: owner)
    deleted_todo = create(:todo, :soft_deleted, user: owner)

    active_ids = Todo.active.pluck(:id)
    expect(active_ids).to include(active_todo.id)
    expect(active_ids).not_to include(deleted_todo.id)
  end

  describe "#soft_delete!" do
    it "sets deleted_at" do
      target = create(:todo, :in_progress, user: owner)
      expect(target.deleted_at).to be_nil
      target.soft_delete!
      expect(target.reload.deleted_at).not_to be_nil
    end
  end

  describe "#active?" do
    context "when not soft-deleted" do
      it "returns true" do
        expect(todo).to be_active
      end
    end

    context "after soft delete" do
      it "returns false" do
        todo.soft_delete!
        expect(todo.reload).not_to be_active
      end
    end
  end
end
