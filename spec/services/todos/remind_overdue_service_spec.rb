require "rails_helper"

RSpec.describe Todos::RemindOverdueService do
  let(:today) { Date.current }

  describe "#call" do
    let!(:user)         { create(:user) }
    let!(:overdue)      { create(:todo, :pending, user: user, estimate_end_at: today - 1) }
    let!(:due_today)    { create(:todo, :in_progress, user: user, estimate_end_at: today) }
    let!(:future)       { create(:todo, :pending, user: user, estimate_end_at: today + 1) }
    let!(:no_date)      { create(:todo, :pending, user: user, estimate_end_at: nil) }
    let!(:completed)    { create(:todo, :completed, user: user, estimate_end_at: today - 1) }
    let!(:soft_deleted) { create(:todo, :pending, :soft_deleted, user: user, estimate_end_at: today - 1) }

    it "sends notifications for overdue todos" do
      expect(Notifications::CreateService).to receive(:call).with(
        hash_including(user: overdue.user, title: "Todo overdue")
      )
      allow(Notifications::CreateService).to receive(:call)
      described_class.new(today).call
    end

    it "sends notifications for due-today todos" do
      expect(Notifications::CreateService).to receive(:call).with(
        hash_including(user: due_today.user, title: "Todo due today")
      )
      allow(Notifications::CreateService).to receive(:call)
      described_class.new(today).call
    end

    it "does not notify for future todos" do
      allow(Notifications::CreateService).to receive(:call)
      described_class.new(today).call
      # future todo should not appear in any call
      expect(Notifications::CreateService).not_to have_received(:call).with(
        hash_including(user: future.user, link: "/todos/#{future.id}")
      )
    end

    it "does not notify for completed todos" do
      allow(Notifications::CreateService).to receive(:call)
      described_class.new(today).call
      expect(Notifications::CreateService).not_to have_received(:call).with(
        hash_including(link: "/todos/#{completed.id}")
      )
    end

    it "does not notify for soft-deleted todos" do
      allow(Notifications::CreateService).to receive(:call)
      described_class.new(today).call
      expect(Notifications::CreateService).not_to have_received(:call).with(
        hash_including(link: "/todos/#{soft_deleted.id}")
      )
    end

    it "returns success with reminded count" do
      allow(Notifications::CreateService).to receive(:call)
      result = described_class.new(today).call
      expect(result).to be_success
      expect(result.data[:reminded]).to eq(2)
    end

    context "with no overdue todos" do
      it "returns success with reminded count of 0" do
        result = described_class.new(today - 5).call
        expect(result).to be_success
        expect(result.data[:reminded]).to eq(0)
      end
    end
  end
end
