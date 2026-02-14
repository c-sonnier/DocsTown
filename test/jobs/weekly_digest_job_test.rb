require "test_helper"

class WeeklyDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @project = create(:project)
    create(:documentation_task, project: @project, status: :voting)
  end

  test "sends digest to opted-in users with email" do
    user = create(:user, email: "digest@example.com", digest_opted_in: true)

    assert_enqueued_emails 1 do
      WeeklyDigestJob.perform_now
    end

    assert_not_nil user.reload.last_digest_sent_at
  end

  test "skips users without email" do
    create(:user, email: nil, digest_opted_in: true)

    assert_no_enqueued_emails do
      WeeklyDigestJob.perform_now
    end
  end

  test "skips users who opted out" do
    create(:user, email: "no@example.com", digest_opted_in: false)

    assert_no_enqueued_emails do
      WeeklyDigestJob.perform_now
    end
  end

  test "idempotency prevents double send within a week" do
    user = create(:user, email: "digest@example.com", digest_opted_in: true, last_digest_sent_at: 2.days.ago)

    assert_no_enqueued_emails do
      WeeklyDigestJob.perform_now
    end
  end

  test "sends again after a week" do
    user = create(:user, email: "digest@example.com", digest_opted_in: true, last_digest_sent_at: 7.days.ago)

    assert_enqueued_emails 1 do
      WeeklyDigestJob.perform_now
    end
  end
end
