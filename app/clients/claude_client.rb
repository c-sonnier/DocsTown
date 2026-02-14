class ClaudeClient < LlmClient
  API_URL = "https://api.anthropic.com/v1/messages"

  private

  def api_url
    API_URL
  end

  def request_headers
    {
      "Content-Type" => "application/json",
      "x-api-key" => Rails.application.credentials.dig(:claude, :api_key) || raise("Missing Claude API key in credentials"),
      "anthropic-version" => "2023-06-01"
    }
  end

  def request_body(prompt)
    { model: "claude-sonnet-4-5-20250929", max_tokens: 1024, messages: [ { role: "user", content: prompt } ] }
  end

  def extract_content(body)
    body.dig("content", 0, "text")
  end

  def provider_name
    "Claude"
  end
end
