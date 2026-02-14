class KimiClient < LlmClient
  API_URL = "https://api.moonshot.cn/v1/chat/completions"

  private

  def api_url
    API_URL
  end

  def request_headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{Rails.application.credentials.dig(:kimi, :api_key) || raise("Missing Kimi API key in credentials")}"
    }
  end

  def request_body(prompt)
    { model: "moonshot-v1-8k", messages: [ { role: "user", content: prompt } ], max_tokens: 1024 }
  end

  def extract_content(body)
    body.dig("choices", 0, "message", "content")
  end

  def provider_name
    "Kimi"
  end
end
