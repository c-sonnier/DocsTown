require "test_helper"

class DigestMailerTest < ActionMailer::TestCase
  setup do
    @user = create(:user, email: "test@example.com", digest_opted_in: true)
    @project = create(:project)
  end

  test "weekly_digest includes stats and links" do
    task = create(:documentation_task, project: @project, status: :voting)
    stats = DigestMailer.compute_weekly_stats
    email = DigestMailer.weekly_digest(@user, stats)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "test@example.com" ], email.to
    assert_equal [ "digest@docstown.org" ], email.from
    assert_includes email.subject, "DocsTown Weekly Digest"
    assert_includes email.body.encoded, @user.github_username
    assert_includes email.body.encoded, task.method_signature
  end

  test "weekly_digest includes unsubscribe headers" do
    create(:documentation_task, project: @project, status: :voting)
    stats = DigestMailer.compute_weekly_stats
    email = DigestMailer.weekly_digest(@user, stats)
    email.deliver_now

    assert email.header["X-List-Unsubscribe"].present?
    assert email.header["X-List-Unsubscribe-Post"].present?
  end

  test "weekly_digest not sent when no activity" do
    stats = DigestMailer.compute_weekly_stats
    email = DigestMailer.weekly_digest(@user, stats)
    assert email.message.is_a?(ActionMailer::Base::NullMail), "Should not send when no activity"
  end

  test "weekly_digest shows merged PR count" do
    create(:documentation_task, project: @project, status: :merged, updated_at: 2.days.ago)
    create(:documentation_task, project: @project, status: :voting)
    stats = DigestMailer.compute_weekly_stats
    email = DigestMailer.weekly_digest(@user, stats)
    email.deliver_now

    assert_includes email.body.encoded, "1" # merged count
  end
end
