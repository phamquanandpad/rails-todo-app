FactoryBot.define do
  factory :todo do
    association :user
    sequence(:task) { |n| "Task #{n}" }
    description { "Some description" }
    status      { :pending }

    trait :in_progress do
      status { :in_progress }
    end

    trait :completed do
      status { :completed }
    end

    trait :soft_deleted do
      deleted_at { 1.day.ago }
    end
  end
end
