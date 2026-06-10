require "rails_helper"

RSpec.describe Permissions::SyncService do
  describe "#call" do
    context "when permission rows are missing from the catalogue" do
      it "creates every permission named in Roles::ALL" do
        result = described_class.call

        expect(Permission.where(name: AppConstants::Roles::ALL).count).to eq(AppConstants::Roles::ALL.size)
        expect(result.data[:permissions_created]).to eq(AppConstants::Roles::ALL.size)
      end

      it "does not recreate permissions that already exist" do
        described_class.call
        result = described_class.call

        expect(result.data[:permissions_created]).to eq(0)
      end
    end

    context "when an existing user is missing permissions their role should have" do
      let!(:member) { create(:user, role: :member) }
      let!(:admin)  { create(:user, role: :admin) }

      it "grants the member their full member permission set" do
        described_class.call

        expect(member.reload.permissions.pluck(:name)).to match_array(AppConstants::Roles::PERMISSIONS[:member])
      end

      it "grants the admin their full admin permission set" do
        described_class.call

        expect(admin.reload.permissions.pluck(:name)).to match_array(AppConstants::Roles::PERMISSIONS[:admin])
      end

      it "reports how many grants it created" do
        result = described_class.call

        expected = AppConstants::Roles::PERMISSIONS[:member].size + AppConstants::Roles::PERMISSIONS[:admin].size
        expect(result.data[:permissions_granted]).to eq(expected)
      end
    end

    context "when a user already has all of their role's permissions" do
      let!(:member) { create(:user, :with_member_permissions, role: :member) }

      it "grants only the permissions they are still missing" do
        result = described_class.call

        already_held = AppConstants::Roles::PERMISSIONS[:member] & member.permissions.pluck(:name)
        still_missing = AppConstants::Roles::PERMISSIONS[:member] - already_held
        expect(result.data[:permissions_granted]).to eq(still_missing.size)
      end

      it "is idempotent on a second run" do
        described_class.call
        result = described_class.call

        expect(result.data[:permissions_granted]).to eq(0)
        expect(member.reload.permissions.pluck(:name)).to match_array(AppConstants::Roles::PERMISSIONS[:member])
      end
    end
  end
end
