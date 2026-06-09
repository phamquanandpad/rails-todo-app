require "rails_helper"

RSpec.describe UserPolicy, type: :model do
  let(:user_has_permission) { create(:user, :with_user_permissions) }
  let(:user)   { create(:user) }

  context "owner" do
    it "can show their own record" do
      expect(UserPolicy.new(user_has_permission, user_has_permission).show?).to be true
    end

    it "can update their own record" do
      expect(UserPolicy.new(user_has_permission, user_has_permission).update?).to be true
    end

    it "can destroy their own record" do
      expect(UserPolicy.new(user_has_permission, user_has_permission).destroy?).to be true
    end
  end

  context "non-owner" do
    it "cannot show another user's record" do
      expect { UserPolicy.new(user, user_has_permission).show? }
        .to raise_error(ApplicationPolicy::Forbidden)
    end

    it "cannot update another user's record" do
      expect { UserPolicy.new(user, user_has_permission).update? }
        .to raise_error(ApplicationPolicy::Forbidden)
    end

    it "cannot destroy another user's record" do
      expect { UserPolicy.new(user, user_has_permission).destroy? }
        .to raise_error(ApplicationPolicy::Forbidden)
    end
  end
end
