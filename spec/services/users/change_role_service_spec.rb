require "rails_helper"

RSpec.describe Users::ChangeRoleService do
  let!(:admin_permissions) do
    AppConstants::Roles::PERMISSIONS[:admin].map { |name| Permission.find_or_create_by!(name: name) }
  end
  let!(:member_permissions) do
    AppConstants::Roles::PERMISSIONS[:member].map { |name| Permission.find_or_create_by!(name: name) }
  end

  let(:user) { create(:user, :with_member_permissions) }

  describe "#call" do
    context "when changing member → admin" do
      it "grants the full admin permission set" do
        result = described_class.call(user: user, role: "admin")

        expect(result.success?).to be true
        expect(user.reload.role).to eq("admin")
        expect(user.permissions.pluck(:name)).to match_array(AppConstants::Roles::PERMISSIONS[:admin])
      end

      it "revokes all previous member-only permissions" do
        described_class.call(user: user, role: "admin")

        member_only = AppConstants::Roles::PERMISSIONS[:member] - AppConstants::Roles::PERMISSIONS[:admin]
        member_only.each do |name|
          expect(user.permissions.exists?(name: name)).to be(false), "expected #{name} to be revoked"
        end
      end
    end

    context "when changing admin → member" do
      let(:user) { create(:user, :with_admin_permissions) }

      it "grants the full member permission set" do
        result = described_class.call(user: user, role: "member")

        expect(result.success?).to be true
        expect(user.reload.role).to eq("member")
        expect(user.permissions.pluck(:name)).to match_array(AppConstants::Roles::PERMISSIONS[:member])
      end
    end

    context "when the role is unchanged" do
      it "returns success without touching permissions" do
        original_count = user.user_permissions.count
        result = described_class.call(user: user, role: "member")

        expect(result.success?).to be true
        expect(user.reload.user_permissions.count).to eq(original_count)
      end
    end

    context "when an invalid role is provided" do
      it "returns failure" do
        result = described_class.call(user: user, role: "superuser")

        expect(result.failure?).to be true
        expect(result.errors).to include(/invalid role/i)
      end

      it "does not change the user's role or permissions" do
        original_role = user.role
        described_class.call(user: user, role: "superuser")

        expect(user.reload.role).to eq(original_role)
      end
    end
  end
end
