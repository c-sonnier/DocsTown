FactoryBot.define do
  factory :user do
    sequence(:github_uid) { |n| n.to_s }
    sequence(:github_username) { |n| "user#{n}" }
    avatar_url { "https://avatars.githubusercontent.com/u/1" }
    email { Faker::Internet.email }
    role { :voter }
    digest_opted_in { true }

    trait :maintainer do
      role { :maintainer }
    end
  end
end
