FactoryBot.define do
  factory :documentation_task do
    project
    status { :drafting }
    sequence(:method_signature) { |n| "ActiveRecord::Base#method_#{n}" }
    source_file_path { "activerecord/lib/active_record/base.rb" }
    source_code { "def example_method\n  # implementation\nend" }
  end
end
