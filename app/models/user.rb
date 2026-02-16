class User < ApplicationRecord
  has_many :votes, dependent: :destroy

  enum :role, { voter: 0, maintainer: 1, admin: 2 }

  validates :github_uid, presence: true, uniqueness: true
  validates :github_username, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def can_administer?
    maintainer? || admin?
  end

  def vote_stats
    total = votes.count
    winning = votes.joins(:draft_version).where(draft_versions: { winner: true }).count
    rate = total > 0 ? (winning.to_f / total * 100).round : 0
    { total_votes: total, winning_picks: winning, win_rate: rate }
  end

  def self.unsubscribe_verifier
    Rails.application.message_verifier("unsubscribe")
  end
end
