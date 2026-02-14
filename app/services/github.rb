module Github
  def self.client
    token = Rails.application.credentials.dig(:github, :access_token) ||
            raise("Missing github.access_token credential")
    Octokit::Client.new(access_token: token)
  end
end
