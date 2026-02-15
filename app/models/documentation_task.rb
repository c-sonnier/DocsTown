class DocumentationTask < ApplicationRecord
  InvalidTransition = Class.new(StandardError)

  CONSENSUS_VOTE_THRESHOLD = 20
  CONSENSUS_PERCENTAGE_THRESHOLD = 50

  belongs_to :project
  has_many :draft_versions, dependent: :destroy
  has_many :votes, dependent: :destroy

  enum :status, { drafting: 0, voting: 1, pending_review: 2, submitted: 3, merged: 4 }
  enum :pr_status, { pending: 0, open: 1, merged: 2, closed: 3 }, prefix: :pr

  scope :by_status, ->(status) { where(status: status) }
  scope :newest, -> { order(created_at: :desc) }
  scope :most_votes, -> {
    left_joins(:votes).group(:id).order(Arel.sql("COUNT(votes.id) DESC"))
  }
  scope :submitted, -> { where(status: :submitted) }
  scope :merged, -> { where(status: :merged) }

  def self.weekly_stats
    one_week_ago = 1.week.ago
    {
      new_voting_tasks: voting.where("created_at >= ? OR updated_at >= ?", one_week_ago, one_week_ago).count,
      submitted_prs: submitted.where(updated_at: one_week_ago..).count,
      merged_prs: merged.where(updated_at: one_week_ago..).count
    }
  end

  validates :method_signature, presence: true, uniqueness: { scope: :project_id }
  validates :source_file_path, presence: true
  validates :source_code, presence: true

  # State transitions

  def start_voting!
    raise InvalidTransition unless drafting?
    update!(status: :voting)
  end

  def finalize_consensus!
    with_lock do
      raise InvalidTransition unless voting?
      raise "No consensus" unless consensus_reached?
      leading_version.update!(winner: true)
      update!(status: :pending_review)
    end
  end

  def approve!
    raise InvalidTransition unless pending_review?
    update!(status: :submitted)
  end

  def reject!(note:)
    raise InvalidTransition unless pending_review?
    transaction do
      draft_versions.where(winner: true).update_all(winner: false)
      update!(status: :voting, reviewer_note: note)
    end
  end

  def mark_merged!
    raise InvalidTransition unless submitted?
    update!(status: :merged, pr_status: :merged)
  end

  def cast_vote!(user:, draft_version_id:)
    draft_version = draft_versions.find(draft_version_id)

    with_lock do
      raise InvalidTransition unless voting?
      existing_vote = user.votes.find_by(documentation_task: self)

      if existing_vote
        # Rails 8 counter_cache handles FK reassignment (decrements old, increments new).
        # If upgrading Rails, verify test "changing vote updates counters on both versions" still passes.
        existing_vote.update!(draft_version: draft_version)
      else
        user.votes.create!(documentation_task: self, draft_version: draft_version)
      end

      reload
      finalize_consensus! if consensus_reached?
    end
  end

  def remove_vote!(user:)
    with_lock do
      raise InvalidTransition unless voting?
      vote = user.votes.find_by!(documentation_task: self)
      vote.destroy!
    end
  end

  # Consensus logic

  def consensus_reached?
    total = votes.count
    return false if total < CONSENSUS_VOTE_THRESHOLD
    leading_version_percentage(total) > CONSENSUS_PERCENTAGE_THRESHOLD
  end

  def leading_version
    draft_versions.order(votes_count: :desc).first
  end

  def leading_version_percentage(total = votes.count)
    return 0 if total.zero?
    return 0 unless leading_version
    (leading_version.votes_count.to_f / total * 100).round(1)
  end

  def winning_version
    draft_versions.find_by(winner: true)
  end

  def build_prompt
    <<~PROMPT
      You are an expert Ruby on Rails documentation writer. Write RDoc-style documentation for the following method.

      Method signature: #{method_signature}
      Source file: #{source_file_path}

      Source code:
      ```ruby
      #{source_code}
      ```

      #{"Class context:\n```ruby\n#{class_context}\n```" if class_context.present?}

      Requirements:
      - Follow Rails RDoc conventions
      - Include a brief description of what the method does
      - Document parameters with their types and descriptions
      - Document return values
      - Include usage examples where helpful
      - Be concise but thorough
    PROMPT
  end

end
