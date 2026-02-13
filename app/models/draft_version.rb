class DraftVersion < ApplicationRecord
  belongs_to :documentation_task
  has_many :votes, dependent: :destroy

  enum :label, { a: 0, b: 1, c: 2 }

  validates :provider, presence: true
  validates :content, presence: true
  validates :label, uniqueness: { scope: :documentation_task_id }
end
