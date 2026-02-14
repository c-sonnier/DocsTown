class User < ApplicationRecord
  has_many :votes, dependent: :destroy

  enum :role, { voter: 0, maintainer: 1, admin: 2 }

  validates :github_uid, presence: true, uniqueness: true
  validates :github_username, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def self.unsubscribe_verifier
    Rails.application.message_verifier("unsubscribe")
  end
end
