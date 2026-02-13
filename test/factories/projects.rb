FactoryBot.define do
  factory :project do
    name { "Ruby on Rails" }
    github_repo { "rails/rails" }
    default_branch { "main" }
  end
end
