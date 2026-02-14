class DigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    user = User.first || FactoryBot.create(:user, email: "preview@example.com")
    DigestMailer.weekly_digest(user)
  end
end
