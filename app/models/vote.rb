class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :documentation_task
  belongs_to :draft_version

  validates :user_id, uniqueness: { scope: :documentation_task_id }
end
