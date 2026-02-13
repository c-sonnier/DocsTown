class ClaudeClient
  API_URL = "https://api.anthropic.com/v1/messages"
  MAX_RETRIES = 3

  def generate(prompt:)
    retries = 0
    begin
      response = Net::HTTP.post(
        URI(API_URL),
        {
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 1024,
          messages: [ { role: "user", content: prompt } ]
        }.to_json,
        "Content-Type" => "application/json",
        "x-api-key" => api_key,
        "anthropic-version" => "2023-06-01"
      )

      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, StandardError => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep backoff_delay(retries)
        retry
      end
      raise
    end
  end

  private

  def handle_response(response)
    body = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Claude API error (#{response.code}): #{body["error"]&.dig("message") || response.body}"
    end

    body.dig("content", 0, "text")
  end

  def api_key
    Rails.application.credentials.dig(:claude, :api_key) || raise("Missing Claude API key in credentials")
  end

  def backoff_delay(attempt)
    return 0 if Rails.env.test?
    5 ** (attempt - 1) # 1s, 5s, 25s
  end
end
