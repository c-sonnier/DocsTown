class DocumentationTask < ApplicationRecord
  InvalidTransition = Class.new(StandardError)

  CONSENSUS_VOTE_THRESHOLD = 20
  CONSENSUS_PERCENTAGE_THRESHOLD = 50

  belongs_to :project
  has_many :draft_versions, dependent: :destroy
  has_many :votes, dependent: :destroy

  enum :status, { drafting: 0, voting: 1, pending_review: 2, submitted: 3, merged: 4 }
  enum :pr_status, { pending: 0, open: 1, merged: 2, closed: 3 }, prefix: :pr

  validates :method_signature, presence: true, uniqueness: { scope: :project_id }
  validates :source_file_path, presence: true
  validates :source_code, presence: true

  # State transitions

  def start_voting!
    raise InvalidTransition unless drafting?
    update!(status: :voting)
  end

  def finalize_consensus!
    raise InvalidTransition unless voting?
    raise "No consensus" unless consensus_reached?
    update!(status: :pending_review)
  end

  def approve!
    raise InvalidTransition unless pending_review?
    update!(status: :submitted)
  end

  def reject!(note:)
    raise InvalidTransition unless pending_review?
    update!(status: :voting, reviewer_note: note)
  end

  def mark_merged!
    raise InvalidTransition unless submitted?
    update!(status: :merged, pr_status: :merged)
  end

  # Consensus logic

  def consensus_reached?
    return false if votes.count < CONSENSUS_VOTE_THRESHOLD
    leading_version_percentage > CONSENSUS_PERCENTAGE_THRESHOLD
  end

  def leading_version
    draft_versions.order(votes_count: :desc).first
  end

  def leading_version_percentage
    return 0 if votes.count.zero?
    (leading_version.votes_count.to_f / votes.count * 100).round(1)
  end

  def winning_version
    draft_versions.find_by(winner: true)
  end

  # Prompt building

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
