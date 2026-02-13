class Project < ApplicationRecord
  has_many :documentation_tasks, dependent: :destroy

  validates :name, presence: true
  validates :github_repo, presence: true, uniqueness: true
end
