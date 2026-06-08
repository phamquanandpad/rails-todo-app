FactoryBot.define do
  factory :refresh_token do
    association :user
    token      { SecureRandom.hex(32) }
    expires_at { 7.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      deleted_at { 1.day.ago }
    end
  end
end
