require "rails_helper"

RSpec.describe Notification, type: :model do
  subject(:notification) { build(:notification) }

  it "is valid with required attributes" do
    expect(notification).to be_valid
  end

  it "requires title" do
    notification.title = nil
    expect(notification).not_to be_valid
    expect(notification.errors[:title]).to include("can't be blank")
  end

  it "requires user" do
    notification.user = nil
    expect(notification).not_to be_valid
  end

  describe "#read?" do
    it "returns false when read_at is nil" do
      notification.read_at = nil
      expect(notification.read?).to be false
    end

    it "returns true when read_at is set" do
      notification.read_at = Time.current
      expect(notification.read?).to be true
    end
  end

  describe "#mark_read!" do
    it "sets read_at" do
      notification.save!
      expect { notification.mark_read! }.to change { notification.reload.read_at }.from(nil)
    end

    it "is idempotent when already read" do
      notification.update!(read_at: 1.day.ago)
      original_read_at = notification.read_at
      notification.mark_read!
      expect(notification.reload.read_at).to be_within(1.second).of(original_read_at)
    end
  end

  describe "scopes" do
    let!(:user) { create(:user) }
    let!(:unread) { create(:notification, user: user) }
    let!(:read)   { create(:notification, :read, user: user) }

    it ".unread returns only unread notifications" do
      expect(user.notifications.unread).to include(unread)
      expect(user.notifications.unread).not_to include(read)
    end

    it ".recent orders by created_at desc" do
      older = create(:notification, user: user, created_at: 2.days.ago)
      newer = create(:notification, user: user, created_at: 1.day.ago)
      ordered = user.notifications.recent.to_a
      expect(ordered.index(newer)).to be < ordered.index(older)
    end
  end
end
