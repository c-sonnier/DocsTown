class User < ApplicationRecord
  has_many :votes, dependent: :destroy

  enum :role, { voter: 0, maintainer: 1 }

  validates :github_uid, presence: true, uniqueness: true
  validates :github_username, presence: true
end
