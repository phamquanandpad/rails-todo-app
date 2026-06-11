require "rails_helper"

RSpec.describe TodosQuery, type: :model do
  let(:user) { create(:user) }
  let(:scope) { user.todos.active }

  before do
    create(:todo, user: user)
    create(:todo, :in_progress, user: user)
    create(:todo, :completed, user: user)
    create(:todo, :soft_deleted, user: user)
  end

  describe "#call" do
    context "when no filters are applied" do
      it "returns all active todos" do
        expect(TodosQuery.new(scope).call.count).to eq(3)
      end
    end

    context "when filtering by status" do
      it "returns only pending todos" do
        todos = TodosQuery.new(scope).call(status: "pending")
        expect(todos.all?(&:pending?)).to be true
      end

      it "returns only in_progress todos" do
        todos = TodosQuery.new(scope).call(status: "in_progress")
        expect(todos.all?(&:in_progress?)).to be true
      end

      it "returns only completed todos" do
        todos = TodosQuery.new(scope).call(status: "completed")
        expect(todos.all?(&:completed?)).to be true
      end
    end

    context "when filtering by overdue" do
      let!(:overdue_todo)    { create(:todo, user: user, estimate_end_at: Date.today - 1) }
      let!(:due_today_todo)  { create(:todo, user: user, estimate_end_at: Date.today) }
      let!(:future_todo)     { create(:todo, user: user, estimate_end_at: Date.today + 1) }
      let!(:no_date_todo)    { create(:todo, user: user, estimate_end_at: nil) }
      let!(:completed_overdue) { create(:todo, :completed, user: user, estimate_end_at: Date.today - 1) }

      it "returns overdue and due-today todos when overdue=true" do
        todos = TodosQuery.new(scope).call(overdue: "true")
        expect(todos).to include(overdue_todo, due_today_todo)
      end

      it "excludes future and nil estimate_end_at todos" do
        todos = TodosQuery.new(scope).call(overdue: "true")
        expect(todos).not_to include(future_todo, no_date_todo)
      end

      it "excludes completed todos even if overdue" do
        todos = TodosQuery.new(scope).call(overdue: "true")
        expect(todos).not_to include(completed_overdue)
      end

      it "does not apply overdue filter when overdue=false" do
        todos = TodosQuery.new(scope).call(overdue: "false")
        expect(todos).to include(future_todo, no_date_todo, completed_overdue)
      end
    end

    it "excludes soft-deleted todos" do
      active_ids = TodosQuery.new(scope).call.pluck(:id)
      deleted_id = user.todos.where.not(deleted_at: nil).pick(:id)
      expect(active_ids).not_to include(deleted_id)
    end

    it "returns todos ordered by created_at desc" do
      todos = TodosQuery.new(scope).call.to_a
      expect(todos).to eq(todos.sort_by { -_1.created_at.to_i })
    end
  end
end
