Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.application.credentials.dig(:github, :oauth_app_id),
    Rails.application.credentials.dig(:github, :oauth_secret),
    scope: "user:email"
end

OmniAuth.config.allowed_request_methods = [ :post ]
