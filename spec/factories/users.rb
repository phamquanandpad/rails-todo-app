FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email)    { |n| "user#{n}@example.com" }
    password              { "password123" }
    password_confirmation { "password123" }

    trait :soft_deleted do
      deleted_at { 1.day.ago }
    end

    # Grants the standard member permission set (todos:*)
    trait :with_member_permissions do
      after(:create) do |user|
        AppConstants::Roles::PERMISSIONS[:member].each do |perm_name|
          permission = Permission.find_or_create_by!(name: perm_name)
          user.permissions << permission unless user.permissions.include?(permission)
        end
      end
    end

    # Grants users:show / users:update / users:destroy
    trait :with_user_permissions do
      after(:create) do |user|
        %w[users:show users:update users:destroy].each do |perm_name|
          permission = Permission.find_or_create_by!(name: perm_name)
          user.permissions << permission unless user.permissions.include?(permission)
        end
      end
    end
  end
end
