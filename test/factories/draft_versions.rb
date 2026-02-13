FactoryBot.define do
  factory :draft_version do
    documentation_task
    label { :a }
    provider { "claude" }
    content { Faker::Lorem.paragraph(sentence_count: 5) }
  end
end
