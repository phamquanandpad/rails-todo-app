require "rails_helper"

RSpec.describe Todos::StartEstimatedService do
  let(:today) { Date.current }

  describe "#call" do
    context "with pending todos starting today" do
      let!(:user)         { create(:user) }
      let!(:matching)     { create(:todo, :pending, user: user, estimate_start_at: today) }
      let!(:tomorrow)     { create(:todo, :pending, user: user, estimate_start_at: today + 1) }
      let!(:no_date)      { create(:todo, :pending, user: user, estimate_start_at: nil) }
      let!(:already_in)   { create(:todo, :in_progress, user: user, estimate_start_at: today) }
      let!(:completed)    { create(:todo, :completed, user: user, estimate_start_at: today) }
      let!(:soft_deleted) { create(:todo, :pending, :soft_deleted, user: user, estimate_start_at: today) }

      it "transitions matching pending todo to in_progress" do
        described_class.new(today).call
        expect(matching.reload).to be_in_progress
      end

      it "does not transition todos with a different start date" do
        described_class.new(today).call
        expect(tomorrow.reload).to be_pending
        expect(no_date.reload).to be_pending
      end

      it "does not transition already-in-progress or completed todos" do
        described_class.new(today).call
        expect(already_in.reload).to be_in_progress
        expect(completed.reload).to be_completed
      end

      it "does not transition soft-deleted todos" do
        described_class.new(today).call
        expect(soft_deleted.reload).to be_pending
      end

      it "sends one notification per transitioned todo" do
        expect(Notifications::CreateService).to receive(:call).once
        described_class.new(today).call
      end

      it "returns success with started count" do
        allow(Notifications::CreateService).to receive(:call)
        result = described_class.new(today).call
        expect(result).to be_success
        expect(result.data[:started]).to eq(1)
      end
    end

    context "with no matching todos" do
      it "returns success with started count of 0" do
        result = described_class.new(today).call
        expect(result).to be_success
        expect(result.data[:started]).to eq(0)
      end
    end
  end
end
