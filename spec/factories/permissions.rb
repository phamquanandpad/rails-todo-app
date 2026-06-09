FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| "permission:action#{n}" }
  end
end
