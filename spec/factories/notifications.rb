FactoryBot.define do
  factory :notification do
    association :user
    title { "Test notification" }
    body  { nil }
    link  { nil }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end

    trait :with_link do
      link { "/todos/1" }
    end
  end
end
