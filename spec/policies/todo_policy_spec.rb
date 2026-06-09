require "rails_helper"

RSpec.describe TodoPolicy, type: :model do
  let(:user_has_permission) { create(:user, :with_member_permissions) }
  let(:user)   { create(:user) }
  let(:todo)  { create(:todo, user: user_has_permission) }

  it "owner can show their todo" do
    expect(TodoPolicy.new(user_has_permission, todo).show?).to be true
  end

  it "non-owner cannot show todo" do
    expect { TodoPolicy.new(user, todo).show? }
      .to raise_error(ApplicationPolicy::Forbidden)
  end

  it "owner can update their todo" do
    expect(TodoPolicy.new(user_has_permission, todo).update?).to be true
  end

  it "non-owner cannot update todo" do
    expect { TodoPolicy.new(user, todo).update? }
      .to raise_error(ApplicationPolicy::Forbidden)
  end

  it "owner can destroy their todo" do
    expect(TodoPolicy.new(user_has_permission, todo).destroy?).to be true
  end

  it "non-owner cannot destroy todo" do
    expect { TodoPolicy.new(user, todo).destroy? }
      .to raise_error(ApplicationPolicy::Forbidden)
  end

  it "any authenticated user with permission can create" do
    user_with_permission = create(:user, :with_member_permissions)
    expect(TodoPolicy.new(user_with_permission, nil).create?).to be true
  end
end
