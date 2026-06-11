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

  describe "estimate window validation" do
    it "is valid when both estimate dates are nil" do
      todo.estimate_start_at = nil
      todo.estimate_end_at   = nil
      expect(todo).to be_valid
    end

    it "is valid when only one estimate date is set" do
      todo.estimate_start_at = Date.today
      todo.estimate_end_at   = nil
      expect(todo).to be_valid
    end

    it "is valid when estimate_end_at equals estimate_start_at" do
      todo.estimate_start_at = Date.today
      todo.estimate_end_at   = Date.today
      expect(todo).to be_valid
    end

    it "is valid when estimate_end_at is after estimate_start_at" do
      todo.estimate_start_at = Date.today
      todo.estimate_end_at   = Date.today + 1
      expect(todo).to be_valid
    end

    it "is invalid when estimate_end_at is before estimate_start_at" do
      todo.estimate_start_at = Date.today + 1
      todo.estimate_end_at   = Date.today
      expect(todo).not_to be_valid
      expect(todo.errors[:estimate_end_at]).to include("must be on or after estimateStartAt")
    end
  end

  describe "#overdue?" do
    let(:today) { Date.current }

    it "returns false when estimate_end_at is nil" do
      todo.estimate_end_at = nil
      expect(todo.overdue?).to be false
    end

    it "returns false when todo is completed even if end date passed" do
      todo.status          = :completed
      todo.estimate_end_at = today - 1
      expect(todo.overdue?).to be false
    end

    it "returns false when end date is in the future" do
      todo.estimate_end_at = today + 1
      expect(todo.overdue?).to be false
    end

    it "returns true when end date equals today and not completed" do
      todo.estimate_end_at = today
      expect(todo.overdue?).to be true
    end

    it "returns true when end date is in the past and not completed" do
      todo.estimate_end_at = today - 1
      expect(todo.overdue?).to be true
    end
  end

  describe "scopes" do
    describe ".starting_on" do
      it "returns todos with estimate_start_at matching the given date" do
        matching = create(:todo, user: owner, estimate_start_at: Date.today)
        other    = create(:todo, user: owner, estimate_start_at: Date.today + 1)
        nil_date = create(:todo, user: owner, estimate_start_at: nil)

        results = Todo.starting_on(Date.today)
        expect(results).to include(matching)
        expect(results).not_to include(other, nil_date)
      end
    end

    describe ".overdue_by" do
      it "returns todos with estimate_end_at on or before the given date" do
        past    = create(:todo, user: owner, estimate_end_at: Date.today - 1)
        today   = create(:todo, user: owner, estimate_end_at: Date.today)
        future  = create(:todo, user: owner, estimate_end_at: Date.today + 1)
        no_date = create(:todo, user: owner, estimate_end_at: nil)

        results = Todo.overdue_by(Date.today)
        expect(results).to include(past, today)
        expect(results).not_to include(future, no_date)
      end
    end
  end
end
