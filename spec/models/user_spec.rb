require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  it "is valid" do
    expect(user).to be_valid
  end

  it "requires username" do
    user.username = nil
    expect(user).not_to be_valid
    expect(user.errors[:username]).to include("can't be blank")
  end

  it "requires email" do
    user.email = nil
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it "validates email format" do
    user.email = "not-an-email"
    expect(user).not_to be_valid
  end

  it "requires unique email" do
    duplicate = user.dup
    duplicate.username = "otherusername"
    expect(duplicate).not_to be_valid
  end

  it "enforces username minimum length" do
    user.username = "a"
    expect(user).not_to be_valid
  end

  it "active scope excludes soft-deleted users" do
    active_user  = create(:user)
    deleted_user = create(:user, :soft_deleted)

    active_ids = User.active.pluck(:id)
    expect(active_ids).to include(active_user.id)
    expect(active_ids).not_to include(deleted_user.id)
  end

  describe "#soft_delete!" do
    it "sets deleted_at" do
      target = create(:user)
      expect(target.deleted_at).to be_nil
      target.soft_delete!
      expect(target.reload.deleted_at).not_to be_nil
    end
  end

  describe "#active?" do
    it "returns false after soft delete" do
      target = create(:user)
      target.soft_delete!
      expect(target.reload).not_to be_active
    end
  end

  it { is_expected.to respond_to(:todos) }
  it { is_expected.to respond_to(:refresh_tokens) }

  describe 'authenticate' do
    context "with valid password" do
      it "returns success" do
        expect(user.authenticate("password123")).to be_truthy
      end
    end
    context "with invalid password" do
      it "returns false" do
        expect(user.authenticate("wrongpassword")).to be_falsy
      end
    end
  end
end
