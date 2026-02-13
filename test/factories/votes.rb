FactoryBot.define do
  factory :vote do
    user
    documentation_task
    draft_version
  end
end
